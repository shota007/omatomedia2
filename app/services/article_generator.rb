require 'json'
require 'net/http'

# 字幕テキストから記事（タイトル・本文・タグ）を生成する
class ArticleGenerator
  MODEL = ENV.fetch('ARTICLE_MODEL', 'claude-haiku-5-5')
  CHUNK_CHARS = 12_000

  def self.call(transcript:, video_title:, channel:, url:)
    new(transcript, video_title, channel, url).call
  end

  def initialize(transcript, video_title, channel, url)
    @transcript, @video_title, @channel, @url = transcript, video_title, channel, url
  end

  def call
    notes = @transcript.length > CHUNK_CHARS ? condensed_notes : @transcript
    data = request(system_prompt, user_prompt(notes), tool: ARTICLE_TOOL)
    {
      title: data['title'].to_s,
      body: data['body'].to_s,
      tags: Array(data['tags']).map(&:to_s).first(5)
    }
  end

  private

  ARTICLE_TOOL = {
    name: 'write_article',
    description: '完成した記事を提出する',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: '記事タイトル' },
        body:  { type: 'string', description: 'Markdown本文（出典を含む）' },
        tags:  { type: 'array', items: { type: 'string' }, description: 'タグ（最大5件）' }
      },
      required: %w[title body tags]
    }
  }.freeze

  # 長尺動画: チャンクごとに要点を抽出してから記事化する
  def condensed_notes
    @transcript.scan(/.{1,#{CHUNK_CHARS}}/m).map do |chunk|
      request('動画の書き起こしの一部から、事実・主張・具体例を漏れなく箇条書きで抽出してください。', chunk)
    end.join("\n")
  end

  def system_prompt
    <<~P
      あなたは日本語のWeb記事ライターです。YouTube動画の書き起こしを元に、読者が動画を見なくても要点を理解できる解説記事を書きます。
      ルール:
      - 書き起こしの丸写しは禁止。要点を再構成し、自分の言葉で書く。
      - 書き起こしにない事実を足さない。
      - 構成は「導入」→「見出し(##)ごとの本文」→「まとめ」。Markdown形式。
      - 末尾に出典として動画タイトル・チャンネル名・URLを記載する。
      完成したら write_article ツールで提出してください。
    P
  end

  def user_prompt(notes)
    <<~P
      動画タイトル: #{@video_title}
      チャンネル: #{@channel}
      URL: #{@url}

      書き起こし:
      #{notes}
    P
  end

  # Anthropic Messages API。tool 指定時はその input(Hash)、なければテキストを返す
  def request(system, user, tool: nil)
    payload = { model: MODEL, max_tokens: 4096, system: system, messages: [{ role: 'user', content: user }] }
    payload.merge!(tools: [tool], tool_choice: { type: 'tool', name: tool[:name] }) if tool

    uri = URI('https://api.anthropic.com/v1/messages')
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, read_timeout: 120) do |http|
      req = Net::HTTP::Post.new(uri, 'content-type' => 'application/json',
                                     'x-api-key' => ENV.fetch('ANTHROPIC_API_KEY'),
                                     'anthropic-version' => '2023-06-01')
      req.body = payload.to_json
      http.request(req)
    end
    json = JSON.parse(res.body)
    raise "Anthropic error: #{json.dig('error', 'message') || res.code}" unless res.is_a?(Net::HTTPSuccess)

    blocks = json['content']
    tool ? blocks.find { |b| b['type'] == 'tool_use' }['input'] : blocks.map { |b| b['text'] }.join
  end
end
