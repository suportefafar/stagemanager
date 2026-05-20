class MediaAsset < ApplicationRecord
  belongs_to :room
  has_one_attached :file

  validates :file, presence: true

  scope :ordered, -> { order(:position) }
  scope :slides, -> { where(media_type: %w[image video]).ordered }
  scope :audios, -> { where(media_type: 'audio').ordered }

  before_create :set_position
  before_create :set_audio_loop_default

  def image?
    file.content_type&.start_with?("image/")
  end

  def video?
    file.content_type&.start_with?("video/")
  end

  def audio?
    file.content_type&.start_with?("audio/")
  end

  def slide?
    image? || video?
  end

  private

  def set_position
    return if media_type == 'audio'
    self.position ||= (room.media_assets.slides.maximum(:position) || 0) + 1
  end

  def set_audio_loop_default
    self.loop = true if media_type == 'audio'
  end
end
