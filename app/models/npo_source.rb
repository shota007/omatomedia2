class NpoSource < ApplicationRecord
  belongs_to :npo

  validates :source_type, presence: true
  validates :url, presence: true
end
