class MediaAsset < ApplicationRecord
  belongs_to :room
  has_one_attached :file
end
