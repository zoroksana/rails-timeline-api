class PostAttachment < ApplicationRecord
  FILE_TYPES = %w[photo video pdf].freeze

  belongs_to :post

  validates :file_type, presence: true, inclusion: { in: FILE_TYPES }
  validates :url, presence: true
end
