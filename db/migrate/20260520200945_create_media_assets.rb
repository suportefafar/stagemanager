class CreateMediaAssets < ActiveRecord::Migration[8.1]
  def change
    create_table :media_assets do |t|
      t.references :room, null: false, foreign_key: true
      t.string :media_type

      t.timestamps
    end
  end
end
