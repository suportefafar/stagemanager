class AddPositionAndTitleToMediaAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :media_assets, :position, :integer, default: 0
    add_column :media_assets, :title, :string
  end
end
