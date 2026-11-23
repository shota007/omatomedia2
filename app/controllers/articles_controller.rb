# YouTube検索 → 字幕取得 → 記事生成 → 保存
class ArticlesController < ApplicationController
  before_action :logged_in_user

  def new
    redirect_to search_articles_path
  end

  # ステップ1: キーワードで動画を検索
  def search
    @query = params[:q].to_s.strip
    @results = []
    return if @query.blank?
    @results = YoutubeSearch.call(@query)
  rescue => e
    Rails.logger.warn("[articles#search] #{e.class}: #{e.message}")
    flash.now[:danger] = "検索に失敗しました。時間をおいて再度お試しください。"
  end

  # ステップ2: 選んだ動画から記事を生成（保存はしない）
  def preview
    @video_id = params.require(:video_id)
    @video_title = params[:video_title].to_s
    @channel = params[:channel].to_s
    url = "https://www.youtube.com/watch?v=#{@video_id}"

    transcript = YoutubeTranscript.call(@video_id)
    article = ArticleGenerator.call(transcript: transcript, video_title: @video_title, channel: @channel, url: url)

    @content = Content.new(
      title: article[:title], article_body: article[:body], tag_list: article[:tags],
      youtube_id: @video_id, source_channel: @channel
    )
    @categories = Category.order(:position)
  rescue YoutubeTranscript::NotFound
    redirect_to search_articles_path(q: params[:q]), alert: "この動画は字幕がないため記事化できません。"
  rescue => e
    Rails.logger.warn("[articles#preview] #{e.class}: #{e.message}")
    redirect_to search_articles_path(q: params[:q]), alert: "記事の生成に失敗しました。"
  end

  # ステップ3: 保存
  def create
    @content = current_user.contents.new(article_params)
    @content.article_mode = true
    @content.category_id ||= Category.order(:position).first&.id
    # サムネイルは保存せず、表示時に youtube_id から YouTube の画像URLを使う（_content.html.erb 参照）
    if @content.save
      redirect_to @content, notice: "記事を保存しました"
    else
      @categories = Category.order(:position)
      render :preview, status: :unprocessable_entity
    end
  end

  private

  def article_params
    p = params.require(:content).permit(:title, :article_body, :youtube_id, :source_channel, :category_id, :tag_list)
    p[:tag_list] = p[:tag_list].to_s.split(/[,\s]+/).map { |t| t.sub(/\A#/, '') }.reject(&:blank?).uniq if p[:tag_list]
    p
  end
end
