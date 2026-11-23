class Content < ApplicationRecord
    before_validation :ensure_default_category
    belongs_to :user
    has_many :comments, dependent: :destroy
    has_one_attached :img_file
    has_one_attached :audio_file
    has_many :favorites, dependent: :destroy
    validates :title,  presence: true
    attr_accessor :remove_img_file # フォームの remove_img_file チェックボックス用
    before_save :purge_img_file, if: -> { remove_img_file == '1' } # 保存前にフラグが立っていれば purge
    attr_accessor :youtube_url
    attr_accessor :skip_post_process_validations
    acts_as_taggable_on :tags

    with_options unless: -> { skip_post_process_validations || article? } do
      validates :audio_file,        presence: true
      validates :transcribed_text,  presence: true
      validates :summarized_text,   presence: true
    end

    validates :article_body, presence: true, if: :article?

    # 記事化コンテンツ（音声・要約を持たない）
    def article?
      article_body.present? || @article_mode
    end
    attr_writer :article_mode

    def favorited_by?(user)
        favorites.exists?(user_id: user.id)
    end

    def self.looks(word)
          @content = Content.where("title LIKE?","%#{word}%").or(Content.where("summarized_text LIKE?","%#{word}%"))
    end
    
    private
      def purge_img_file
        img_file.purge
      end
      def ensure_default_category
        return if category_id.present?
        default = Category.order(:position).first || Category.first
        self.category_id = default&.id
      end
end
