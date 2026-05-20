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
        render turbo_stream: turbo_stream.replace("carousel_message",
          partial: "rooms/carousel_message",
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
end
