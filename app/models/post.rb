class Post < ApplicationRecord
  attr_accessor :attachment_file

  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likable, dependent: :destroy
  has_many :post_attachments, dependent: :destroy

  accepts_nested_attributes_for :post_attachments, allow_destroy: true

  validates :date, presence: true
  validates :description, presence: true

  SORT_COLUMNS = {
    "date" => :date,
    "created_at" => :created_at
  }.freeze

  scope :timeline_order, lambda { |sort, direction|
    column = SORT_COLUMNS.fetch(sort, :date)
    if column == :created_at
      order(created_at: normalize_direction(direction), id: :desc)
    else
      order(column => normalize_direction(direction), created_at: :desc)
    end
  }

  def self.normalize_direction(direction)
    direction.to_s.downcase == "asc" ? :asc : :desc
  end
end
