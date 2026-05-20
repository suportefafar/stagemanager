class AddLoopToMediaAssets < ActiveRecord::Migration[8.1]
  def change
    add_column :media_assets, :loop, :boolean, default: false, null: false
  end
end
