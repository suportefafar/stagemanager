class CreateRooms < ActiveRecord::Migration[8.1]
  def change
    create_table :rooms do |t|
      t.string :passcode
      t.integer :timer_duration
      t.integer :timer_remaining
      t.string :timer_status
      t.string :message
      t.integer :current_slide

      t.timestamps
    end
    add_index :rooms, :passcode, unique: true
  end
end
