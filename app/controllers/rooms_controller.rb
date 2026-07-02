class RoomsController < ApplicationController
  before_action :set_room, except: [:create]

  def create
    @room = Room.find_or_create_by(passcode: params[:passcode])
    if @room.persisted?
      redirect_to manager_room_path(@room.passcode)
    else
      redirect_to root_path, alert: "Could not create or find room."
    end
  end

  def manager
  end

  def timer
    render layout: "fullscreen"
  end

  def presentation
    render layout: "fullscreen"
  end

  def update_timer
    if params[:action_type] == 'start'
      @room.update(timer_status: 'playing')
      TimerTickJob.set(wait: 1.second).perform_later(@room.id)
    elsif params[:action_type] == 'pause'
      @room.update(timer_status: 'paused')
    elsif params[:action_type] == 'stop'
      @room.update(timer_status: 'stopped', timer_remaining: @room.timer_duration)
    elsif params[:action_type] == 'add'
      amount = params[:amount].to_i > 0 ? params[:amount].to_i : 60
      @room.update(timer_remaining: @room.timer_remaining + amount)
    elsif params[:action_type] == 'sub'
      amount = params[:amount].to_i > 0 ? params[:amount].to_i : 60
      @room.update(timer_remaining: [@room.timer_remaining - amount, 0].max)
    elsif params[:action_type] == 'set_duration'
      duration_str = params[:duration_str].to_s.strip
      if duration_str.include?(":")
        minutes, seconds = duration_str.split(":")
        total_seconds = minutes.to_i * 60 + seconds.to_i
      else
        total_seconds = duration_str.to_i * 60
      end
      total_seconds = 60 if total_seconds <= 0
      @room.update(timer_duration: total_seconds, timer_remaining: total_seconds, timer_status: 'stopped')
    end

    @room.reload
    broadcast_room_update

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("timer_display",
            partial: "rooms/timer_display",
            locals: { room: @room }),
          turbo_stream.replace("manager_controls",
            partial: "rooms/manager_controls",
            locals: { room: @room })
        ]
      end
      format.html { redirect_to manager_room_path(@room.passcode) }
    end
  end

  def update_message
    @room.update(message: params[:message])
    broadcast_message_update

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("carousel_message",
            partial: "rooms/carousel_message",
            locals: { room: @room }),
          turbo_stream.replace("message_form",
            partial: "rooms/message_form",
            locals: { room: @room })
        ]
      end
      format.html { redirect_to manager_room_path(@room.passcode) }
    end
  end

  def update_slide
    if @room.total_slides > 0
      case params[:action_type]
      when 'next'
        new_slide = [@room.current_slide + 1, @room.total_slides].min
        @room.update(current_slide: new_slide)
      when 'prev'
        new_slide = [@room.current_slide - 1, 1].max
        @room.update(current_slide: new_slide)
      when 'goto'
        slide_num = params[:slide_number].to_i.clamp(1, @room.total_slides)
        @room.update(current_slide: slide_num)
      end
    end

    @room.reload
    broadcast_presentation_update

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("media_panel",
          partial: "rooms/media_panel",
          locals: { room: @room })
      end
      format.html { redirect_to manager_room_path(@room.passcode) }
    end
  end

  def update_audio
    case params[:action_type]
    when 'play'
      @room.update(current_audio_id: params[:audio_id])
    when 'stop'
      @room.update(current_audio_id: nil)
    end

    @room.reload
    broadcast_audio_update

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("media_panel",
          partial: "rooms/media_panel",
          locals: { room: @room })
      end
      format.html { redirect_to manager_room_path(@room.passcode) }
    end
  end

  private

  def set_room
    @room = Room.find_by!(passcode: params[:passcode])
  end

  def broadcast_room_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_timer",
      target: "timer_display",
      partial: "rooms/timer_display",
      locals: { room: @room }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_timer",
      target: "manager_controls",
      partial: "rooms/manager_controls",
      locals: { room: @room }
    )
  end

  def broadcast_message_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_message",
      target: "carousel_message",
      partial: "rooms/carousel_message",
      locals: { room: @room }
    )
  end

  def broadcast_presentation_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_presentation",
      target: "presentation_display",
      partial: "rooms/presentation_display",
      locals: { room: @room }
    )
  end

  def broadcast_audio_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{@room.id}_presentation",
      target: "audio_player",
      partial: "rooms/audio_player",
      locals: { room: @room }
    )
  end
end
