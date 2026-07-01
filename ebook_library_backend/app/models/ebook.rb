class Ebook < ApplicationRecord
  has_one_attached :file
  has_one_attached :cover

  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_TYPES = %w[application/pdf application/epub+zip].freeze

  validates :title, presence: true
  validates :file, presence: true
  validate :acceptable_file

  before_validation :set_file_metadata

  scope :search, ->(query) {
    return all if query.blank?

    where("title LIKE :q OR author LIKE :q OR file_name LIKE :q", q: "%#{query}%")
  }

  def as_json_summary
    {
      id: id,
      title: title,
      author: author,
      file_type: file_type,
      file_size: file_size,
      file_name: file_name,
      created_at: created_at,
      cover_url: cover.attached? ? Rails.application.routes.url_helpers.rails_blob_path(cover, only_path: true) : nil,
      download_url: file.attached? ? "/api/ebooks/#{id}/download" : nil
    }
  end

  private

  def set_file_metadata
    return unless file.attached?

    self.file_type ||= file.content_type
    self.file_size ||= file.byte_size
    self.file_name ||= file.filename.to_s
  end

  def acceptable_file
    return unless file.attached?

    unless ALLOWED_TYPES.include?(file.content_type)
      errors.add(:file, "must be a PDF or EPUB")
    end

    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "is too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)")
    end
  end
end