class AddCurrentAudioIdToRooms < ActiveRecord::Migration[8.1]
  def change
    add_column :rooms, :current_audio_id, :bigint, null: true
  end
end
