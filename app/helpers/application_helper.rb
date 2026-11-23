module ApplicationHelper
    def up_time(content)
        @today = Date.today
        @now = Time.now
        if (@now - content.created_at) <= 60 * 60
            ((@now - content.created_at) / 60).to_i.to_s + "mins ago"
        elsif (@now - content.created_at) <= 60 * 60 * 24
            ((@now - content.created_at) / 3600).to_i.to_s + "hr ago"
        elsif (@today - content.created_at.to_date) <= 30
            (@today - content.created_at.to_date).to_i.to_s + "days ago"
        else
            content.created_at.strftime('%F')
        end
    end


    # タイムライン用の抜粋（Markdownの見出し・出典を除いたプレーンテキスト）
    def timeline_excerpt(content, length: 140)
        text = content.article_body.presence || content.summarized_text.presence || content.transcribed_text.to_s
        text = text.split(/^\s*---\s*$/).first.to_s
        text = text.lines.reject { |l| l.strip.start_with?('#') }.join(' ')
        text = text.gsub(/[*_`>]|^\s*-\s+/, '').gsub(/\s+/, ' ').strip
        text.truncate(length)
    end

    def timeline_thumb(content)
        if content.img_file.attached?
            url_for(content.img_file)
        elsif content.youtube_id.present?
            "https://img.youtube.com/vi/#{content.youtube_id}/hqdefault.jpg"
        end
    end
end
