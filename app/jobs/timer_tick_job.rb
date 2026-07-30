class TimerTickJob < ApplicationJob
  queue_as :default

  def perform(room_id)
    room = Room.find_by(id: room_id)
    return unless room
    return unless room.timer_status == "playing"

    room.update_column(:timer_remaining, room.timer_remaining - 1)
    room.reload

    # Broadcast updated state to all subscribers
    broadcast_timer(room)

    if room.timer_remaining > 0 && room.timer_status == "playing"
      TimerTickJob.set(wait: 1.second).perform_later(room_id)
    else
      # Timer finished — auto-stop
      room.update_columns(timer_status: "stopped")
      broadcast_timer(room)
    end
  end

  private

  def broadcast_timer(room)
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{room.id}_timer",
      target: "timer_display",
      partial: "rooms/timer_display",
      locals: { room: room }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "room_#{room.id}_timer",
      target: "manager_controls",
      partial: "rooms/manager_controls",
      locals: { room: room }
    )
  end
end
