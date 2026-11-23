require 'google/apis/youtube_v3'

# キーワードでYouTube動画を検索する（Data API v3 search.list）
class YoutubeSearch
  Result = Struct.new(:video_id, :title, :channel, :thumbnail, :published_at, keyword_init: true) do
    def url = "https://www.youtube.com/watch?v=#{video_id}"
  end

  def self.call(query, max_results: 10, language: 'ja')
    svc = Google::Apis::YoutubeV3::YouTubeService.new
    svc.key = ENV['GOOGLE_CLIENT_API_KEY']
    res = svc.list_searches(
      'snippet',
      q: query, type: 'video', max_results: max_results,
      relevance_language: language
    )
    res.items.map do |item|
      s = item.snippet
      Result.new(
        video_id: item.id.video_id, title: s.title, channel: s.channel_title,
        thumbnail: "https://img.youtube.com/vi/#{item.id.video_id}/hqdefault.jpg",
        published_at: s.published_at
      )
    end
  end
end
