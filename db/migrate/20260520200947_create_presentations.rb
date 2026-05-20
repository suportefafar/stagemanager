class CreatePresentations < ActiveRecord::Migration[8.1]
  def change
    create_table :presentations do |t|
      t.references :room, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
