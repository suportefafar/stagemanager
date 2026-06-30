require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
  end

  # ── CREATE ──────────────────────────────────────────────────────
  test "create with new passcode creates room and redirects to manager" do
    assert_difference "Room.count", 1 do
      post rooms_url, params: { passcode: "brand-new-room" }
    end
    new_room = Room.find_by(passcode: "brand-new-room")
    assert_not_nil new_room
    assert_redirected_to manager_room_path("brand-new-room")
  end

  test "create with existing passcode finds room without creating" do
    assert_no_difference "Room.count" do
      post rooms_url, params: { passcode: @room.passcode }
    end
    assert_redirected_to manager_room_path(@room.passcode)
  end

  # ── MANAGER ─────────────────────────────────────────────────────
  test "should get manager" do
    get manager_room_url(@room.passcode)
    assert_response :success
  end

  test "manager page contains timer controls" do
    get manager_room_url(@room.passcode)
    assert_select "#manager_controls"
    assert_select "#timer_display"
  end

  test "manager page contains media panel" do
    get manager_room_url(@room.passcode)
    assert_select "#media_panel"
  end

  test "manager page contains message form" do
    get manager_room_url(@room.passcode)
    assert_select "textarea[name='message']"
  end

  test "manager with invalid passcode returns 404" do
    get manager_room_url("nonexistent-room")
    assert_response :not_found
  end

  # ── TIMER VIEW ──────────────────────────────────────────────────
  test "should get timer" do
    get timer_room_url(@room.passcode)
    assert_response :success
  end

  test "timer uses fullscreen layout" do
    get timer_room_url(@room.passcode)
    assert_select ".clock-text"
  end

  # ── PRESENTATION VIEW ──────────────────────────────────────────
  test "should get presentation" do
    get presentation_room_url(@room.passcode)
    assert_response :success
  end

  test "presentation shows no-active message when no slides" do
    room = rooms(:two)  # no media assets
    get presentation_room_url(room.passcode)
    assert_select "#presentation_display"
  end

  # ── UPDATE TIMER ────────────────────────────────────────────────
  test "update_timer start sets status to playing" do
    @room.update!(timer_status: "stopped")
    patch update_timer_room_url(@room.passcode), params: { action_type: "start" }
    @room.reload
    assert_equal "playing", @room.timer_status
  end

  test "update_timer pause sets status to paused" do
    @room.update!(timer_status: "playing")
    patch update_timer_room_url(@room.passcode), params: { action_type: "pause" }
    @room.reload
    assert_equal "paused", @room.timer_status
  end

  test "update_timer stop resets status and timer_remaining" do
    @room.update!(timer_status: "playing", timer_remaining: 100, timer_duration: 600)
    patch update_timer_room_url(@room.passcode), params: { action_type: "stop" }
    @room.reload
    assert_equal "stopped", @room.timer_status
    assert_equal 600, @room.timer_remaining
  end

  test "update_timer add increases timer_remaining" do
    @room.update!(timer_remaining: 100)
    patch update_timer_room_url(@room.passcode), params: { action_type: "add", amount: 120 }
    @room.reload
    assert_equal 220, @room.timer_remaining
  end

  test "update_timer add defaults to 60 seconds" do
    @room.update!(timer_remaining: 100)
    patch update_timer_room_url(@room.passcode), params: { action_type: "add" }
    @room.reload
    assert_equal 160, @room.timer_remaining
  end

  test "update_timer sub decreases timer_remaining" do
    @room.update!(timer_remaining: 200)
    patch update_timer_room_url(@room.passcode), params: { action_type: "sub", amount: 60 }
    @room.reload
    assert_equal 140, @room.timer_remaining
  end

  test "update_timer sub does not go below zero" do
    @room.update!(timer_remaining: 30)
    patch update_timer_room_url(@room.passcode), params: { action_type: "sub", amount: 60 }
    @room.reload
    assert_equal 0, @room.timer_remaining
  end

  test "update_timer set_duration with minutes-only string" do
    patch update_timer_room_url(@room.passcode), params: { action_type: "set_duration", duration_str: "15" }
    @room.reload
    assert_equal 900, @room.timer_duration
    assert_equal 900, @room.timer_remaining
    assert_equal "stopped", @room.timer_status
  end

  test "update_timer set_duration with MM:SS string" do
    patch update_timer_room_url(@room.passcode), params: { action_type: "set_duration", duration_str: "5:30" }
    @room.reload
    assert_equal 330, @room.timer_duration
    assert_equal 330, @room.timer_remaining
  end

  test "update_timer set_duration rejects zero and defaults to 60" do
    patch update_timer_room_url(@room.passcode), params: { action_type: "set_duration", duration_str: "0" }
    @room.reload
    assert_equal 60, @room.timer_duration
  end

  test "update_timer responds with turbo_stream" do
    patch update_timer_room_url(@room.passcode),
      params: { action_type: "start" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "update_timer responds with html redirect" do
    patch update_timer_room_url(@room.passcode),
      params: { action_type: "start" },
      headers: { "Accept" => "text/html" }
    assert_redirected_to manager_room_path(@room.passcode)
  end

  # ── UPDATE MESSAGE ──────────────────────────────────────────────
  test "update_message sets room message" do
    patch update_message_room_url(@room.passcode), params: { message: "Hello World!" }
    @room.reload
    assert_equal "Hello World!", @room.message
  end

  test "update_message can clear message" do
    @room.update!(message: "old message")
    patch update_message_room_url(@room.passcode), params: { message: "" }
    @room.reload
    assert_equal "", @room.message
  end

  test "update_message responds with turbo_stream" do
    patch update_message_room_url(@room.passcode),
      params: { message: "Test" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  # ── UPDATE SLIDE ────────────────────────────────────────────────
  test "update_slide next increments current_slide" do
    @room.update!(current_slide: 1)
    patch update_slide_room_url(@room.passcode), params: { action_type: "next" }
    @room.reload
    assert_equal 2, @room.current_slide
  end

  test "update_slide next does not exceed total_slides" do
    total = @room.total_slides
    @room.update!(current_slide: total)
    patch update_slide_room_url(@room.passcode), params: { action_type: "next" }
    @room.reload
    assert_equal total, @room.current_slide
  end

  test "update_slide prev decrements current_slide" do
    @room.update!(current_slide: 2)
    patch update_slide_room_url(@room.passcode), params: { action_type: "prev" }
    @room.reload
    assert_equal 1, @room.current_slide
  end

  test "update_slide prev does not go below 1" do
    @room.update!(current_slide: 1)
    patch update_slide_room_url(@room.passcode), params: { action_type: "prev" }
    @room.reload
    assert_equal 1, @room.current_slide
  end

  test "update_slide goto jumps to specific slide" do
    @room.update!(current_slide: 1)
    patch update_slide_room_url(@room.passcode), params: { action_type: "goto", slide_number: 3 }
    @room.reload
    assert_equal 3, @room.current_slide
  end

  test "update_slide goto clamps to valid range" do
    @room.update!(current_slide: 1)
    patch update_slide_room_url(@room.passcode), params: { action_type: "goto", slide_number: 999 }
    @room.reload
    assert_equal @room.total_slides, @room.current_slide
  end

  test "update_slide on room with no slides does nothing" do
    room = rooms(:two)
    patch update_slide_room_url(room.passcode), params: { action_type: "next" }
    room.reload
    assert_equal 1, room.current_slide
  end

  # ── UPDATE AUDIO ────────────────────────────────────────────────
  test "update_audio play sets current_audio_id" do
    audio = media_assets(:audio_one)
    patch update_audio_room_url(@room.passcode), params: { action_type: "play", audio_id: audio.id }
    @room.reload
    assert_equal audio.id, @room.current_audio_id
  end

  test "update_audio stop clears current_audio_id" do
    audio = media_assets(:audio_one)
    @room.update!(current_audio_id: audio.id)
    patch update_audio_room_url(@room.passcode), params: { action_type: "stop" }
    @room.reload
    assert_nil @room.current_audio_id
  end
end
