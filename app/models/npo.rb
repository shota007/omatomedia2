class Npo < ApplicationRecord
  # 統制語彙（フォームの選択肢・インポーターからの自動分類の候補として使う）
  # 自由記述のタグ追加も許容するが、まずはこのリストへの正規化を優先する
  PARTNERSHIP_TYPES = [
    "事業連携",
    "CSR連携（寄付受入）",
    "CSR連携（社員ボランティア受入）",
    "CSR連携（冠協賛・イベント共催）",
    "物品・サービス提供",
    "販路・PR支援",
  ].freeze

  INVOLVEMENT_TYPES = [
    "寄付",
    "会員・サポーター登録",
    "ボランティア参加",
    "イベント参加",
    "情報発信・SNS拡散",
    "専門スキル提供（プロボノ）",
  ].freeze

  FIELDS = [
    "子ども・教育",
    "福祉",
    "環境",
    "まちづくり",
    "国際協力",
    "災害支援",
    "医療・健康",
    "文化・芸術",
    "動物愛護",
    "人権・平和",
  ].freeze

  has_many :npo_sources, dependent: :destroy
  accepts_nested_attributes_for :npo_sources, allow_destroy: true

  # 分類軸ごとにタグのコンテキストを分ける
  # - partnership_types: 企業との連携タイプ（事業連携・CSR連携など）
  # - involvement_types : 一般の方の関わり方（寄付・ボランティアなど）
  # - fields            : 活動分野（子ども支援・環境など）
  acts_as_taggable_on :partnership_types, :involvement_types, :fields

  enum status: { draft: 0, published: 1, archived: 2 }

  validates :name, presence: true
  validates :corporate_number, uniqueness: true, allow_blank: true

  scope :search, ->(word) {
    where("name LIKE :w OR summary LIKE :w", w: "%#{word}%")
  }
end
