class Room < ApplicationRecord
  has_many :media_assets, dependent: :destroy
  has_many :presentations, dependent: :destroy

  validates :passcode, presence: true, uniqueness: true
  after_initialize :set_defaults, unless: :persisted?

  def current_media_asset
    media_assets.slides.offset(current_slide.to_i - 1).first
  end

  def total_slides
    media_assets.slides.count
  end

  def current_audio
    media_assets.find_by(id: current_audio_id) if current_audio_id
  end

  def video_playing?
    current_media_asset&.video?
  end

  private

  def set_defaults
    self.timer_duration ||= 600
    self.timer_remaining ||= 600
    self.timer_status ||= 'stopped'
    self.current_slide ||= 1
  end
end
