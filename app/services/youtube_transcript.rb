require 'open3'
require 'tmpdir'

# yt-dlp で字幕（手動 or 自動生成）だけ取得し、プレーンテキストにする。音声DLは行わない。
class YoutubeTranscript
  class NotFound < StandardError; end

  LANGS = 'ja,ja-orig,en'.freeze

  def self.call(video_id)
    Dir.mktmpdir do |dir|
      _out, err, status = Open3.capture3(
        'yt-dlp', '--skip-download', '--no-playlist',
        '--write-subs', '--write-auto-subs',
        '--sub-langs', LANGS, '--sub-format', 'vtt',
        '--output', File.join(dir, '%(id)s.%(ext)s'),
        "https://www.youtube.com/watch?v=#{video_id}"
      )
      file = Dir[File.join(dir, '*.vtt')].min_by { |f| lang_rank(f) }
      raise NotFound, "字幕が取得できませんでした: #{err.to_s.lines.last}" unless file
      parse_vtt(File.read(file))
    end
  end

  def self.lang_rank(path)
    LANGS.split(',').index { |l| path.include?(".#{l}.") } || 99
  end

  # WebVTTからタイムコード・タグ・重複行を除去
  def self.parse_vtt(vtt)
    lines = vtt.lines.map(&:strip).reject do |l|
      l.empty? || l.start_with?('WEBVTT', 'Kind:', 'Language:', 'NOTE') || l.include?('-->') || l.match?(/\A\d+\z/)
    end
    lines = lines.map { |l| l.gsub(/<[^>]+>/, '').gsub('&nbsp;', ' ').strip }.reject(&:empty?)
    lines.chunk_while { |a, b| a == b }.map(&:first).join("\n")
  end
end
