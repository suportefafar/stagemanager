class MediaAssetsController < ApplicationController
  before_action :set_room

  def create
    files = Array(params.dig(:media_asset, :files)).compact_blank

    files.each do |file|
      @room.media_assets.create!(
        file: file,
        media_type: file.content_type&.split("/")&.first
      )
    end

    broadcast_presentation_update
    redirect_to manager_room_path(@room.passcode), notice: "#{files.size} file(s) uploaded."
  end

  def update
    asset = @room.media_assets.find(params[:id])
    update_params = params.require(:media_asset).permit(:title, :loop)
    asset.update(update_params)

    if asset.slide? && @room.current_media_asset&.id == asset.id
      broadcast_presentation_update
    end
    if asset.audio? && @room.current_audio_id == asset.id
      broadcast_audio_update
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("media_panel",
          partial: "rooms/media_panel",
          locals: { room: @room.reload })
      end
      format.html { redirect_to manager_room_path(@room.passcode) }
    end
  end

  def destroy
    asset = @room.media_assets.find(params[:id])
    was_audio = asset.audio?
    was_current_audio = @room.current_audio_id == asset.id

    asset.destroy

    if was_audio
      # Clear current audio if we just deleted it
      @room.update(current_audio_id: nil) if was_current_audio
      broadcast_audio_update if was_current_audio
    else
      # Reorder remaining slides
      @room.media_assets.slides.each_with_index do |ma, i|
        ma.update_column(:position, i + 1)
      end

      # Adjust current_slide if needed
      if @room.total_slides > 0
        @room.update(current_slide: @room.current_slide.clamp(1, @room.total_slides))
      else
        @room.update(current_slide: 1)
      end

      broadcast_presentation_update
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("media_panel",
          partial: "rooms/media_panel",
          locals: { room: @room.reload })
      end
      format.html { redirect_to manager_room_path(@room.passcode) }
    end
  end

  private

  def set_room
    @room = Room.find_by!(passcode: params[:room_passcode])
  end

  def broadcast_presentation_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_presentation",
      target: "presentation_display",
      partial: "rooms/presentation_display",
      locals: { room: @room.reload }
    )
  end

  def broadcast_audio_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_presentation",
      target: "audio_player",
      partial: "rooms/audio_player",
      locals: { room: @room.reload }
    )
  end
end
