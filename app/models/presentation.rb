class Presentation < ApplicationRecord
  belongs_to :room
  has_one_attached :original_file
  has_one_attached :converted_pdf

  after_initialize :set_defaults, unless: :persisted?

  private

  def set_defaults
    self.status ||= 'processing'
  end
end
