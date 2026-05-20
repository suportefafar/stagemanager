class Room < ApplicationRecord
  has_many :media_assets, dependent: :destroy
  has_many :presentations, dependent: :destroy

  validates :passcode, presence: true, uniqueness: true
  after_initialize :set_defaults, unless: :persisted?

  private

  def set_defaults
    self.timer_duration ||= 600
    self.timer_remaining ||= 600
    self.timer_status ||= 'stopped'
    self.current_slide ||= 1
  end
end
