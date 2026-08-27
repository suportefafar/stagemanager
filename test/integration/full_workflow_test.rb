require "test_helper"

class FullWorkflowTest < ActionDispatch::IntegrationTest
  # ══════════════════════════════════════════════════════════════════
  # End-to-end: Create room → Upload media → Navigate → Timer → Msg
  # ══════════════════════════════════════════════════════════════════

  test "full room lifecycle: create, manage, upload, navigate, timer, message" do
    # ── Step 1: Visit homepage ──────────────────────────────────────
    get root_url
    assert_response :success
    assert_select "input[name='passcode']"

    # ── Step 2: Create a new room ───────────────────────────────────
    post rooms_url, params: { passcode: "e2e-test-room" }
    assert_redirected_to manager_room_path("e2e-test-room")
    follow_redirect!
    assert_response :success

    room = Room.find_by!(passcode: "e2e-test-room")
    assert_equal 600, room.timer_duration
    assert_equal "stopped", room.timer_status
    assert_equal 1, room.current_slide

    # ── Step 3: Upload slide files ──────────────────────────────────
    file1 = fixture_file_upload("test_image.png", "image/png")
    file2 = fixture_file_upload("test_image.png", "image/png")

    assert_difference "room.media_assets.count", 2 do
      post room_media_assets_url(room.passcode), params: {
        media_asset: { files: [ file1, file2 ] }
      }
    end
    assert_redirected_to media_room_path(room.passcode)

    assert_equal 2, room.total_slides
    assert_equal "image", room.media_assets.slides.first.media_type

    # ── Step 4: Upload audio file ───────────────────────────────────
    audio = fixture_file_upload("test_audio.wav", "audio/wav")
    post room_media_assets_url(room.passcode), params: {
      media_asset: { files: [ audio ] }
    }

    audio_asset = room.media_assets.audios.last
    assert_not_nil audio_asset
    assert audio_asset.loop, "audio should default to loop"

    # ── Step 5: Navigate slides ─────────────────────────────────────
    assert_equal 1, room.current_slide

    patch update_slide_room_url(room.passcode), params: { action_type: "next" }
    room.reload
    assert_equal 2, room.current_slide

    patch update_slide_room_url(room.passcode), params: { action_type: "next" }
    room.reload
    assert_equal 2, room.current_slide, "should not go beyond total_slides"

    patch update_slide_room_url(room.passcode), params: { action_type: "prev" }
    room.reload
    assert_equal 1, room.current_slide

    patch update_slide_room_url(room.passcode), params: { action_type: "goto", slide_number: 2 }
    room.reload
    assert_equal 2, room.current_slide

    # ── Step 6: Timer controls ──────────────────────────────────────
    patch update_timer_room_url(room.passcode), params: { action_type: "set_duration", duration_str: "10:00" }
    room.reload
    assert_equal 600, room.timer_duration
    assert_equal 600, room.timer_remaining
    assert_equal "stopped", room.timer_status

    patch update_timer_room_url(room.passcode), params: { action_type: "start" }
    room.reload
    assert_equal "playing", room.timer_status

    patch update_timer_room_url(room.passcode), params: { action_type: "add", amount: 120 }
    room.reload
    assert_equal 720, room.timer_remaining

    patch update_timer_room_url(room.passcode), params: { action_type: "sub", amount: 60 }
    room.reload
    assert_equal 660, room.timer_remaining

    patch update_timer_room_url(room.passcode), params: { action_type: "pause" }
    room.reload
    assert_equal "paused", room.timer_status

    patch update_timer_room_url(room.passcode), params: { action_type: "stop" }
    room.reload
    assert_equal "stopped", room.timer_status
    assert_equal 600, room.timer_remaining

    # ── Step 7: Message broadcast ───────────────────────────────────
    patch update_message_room_url(room.passcode), params: { message: "Hello audience!" }
    room.reload
    assert_equal "Hello audience!", room.message

    # ── Step 8: Audio controls ──────────────────────────────────────
    patch update_audio_room_url(room.passcode), params: { action_type: "play", audio_id: audio_asset.id }
    room.reload
    assert_equal audio_asset.id, room.current_audio_id

    patch update_audio_room_url(room.passcode), params: { action_type: "stop" }
    room.reload
    assert_nil room.current_audio_id

    # ── Step 9: Delete a slide and verify reordering ────────────────
    first_slide = room.media_assets.slides.first
    delete room_media_asset_url(room.passcode, first_slide)

    room.reload
    assert_equal 1, room.total_slides
    remaining_slide = room.media_assets.slides.first
    assert_equal 1, remaining_slide.position, "remaining slide should be reordered to position 1"

    # ── Step 10: Delete audio and verify cleanup ────────────────────
    room.update!(current_audio_id: audio_asset.id)
    delete room_media_asset_url(room.passcode, audio_asset)
    room.reload
    assert_nil room.current_audio_id

    # ── Step 11: Verify viewer screens still load ───────────────────
    get timer_room_url(room.passcode)
    assert_response :success

    get presentation_room_url(room.passcode)
    assert_response :success

    # ── Step 12: Re-entering existing room doesn't duplicate ────────
    assert_no_difference "Room.count" do
      post rooms_url, params: { passcode: "e2e-test-room" }
    end
    assert_redirected_to manager_room_path("e2e-test-room")
  end

  # ══════════════════════════════════════════════════════════════════
  # Edge case: room with no media at all
  # ══════════════════════════════════════════════════════════════════

  test "room with no media handles all actions gracefully" do
    post rooms_url, params: { passcode: "empty-room" }
    room = Room.find_by!(passcode: "empty-room")

    # Timer works even with no media
    patch update_timer_room_url(room.passcode), params: { action_type: "start" }
    room.reload
    assert_equal "playing", room.timer_status

    # Slide navigation does nothing on empty room
    patch update_slide_room_url(room.passcode), params: { action_type: "next" }
    room.reload
    assert_equal 1, room.current_slide

    patch update_slide_room_url(room.passcode), params: { action_type: "prev" }
    room.reload
    assert_equal 1, room.current_slide

    # Presentation page loads fine with no slides
    get presentation_room_url(room.passcode)
    assert_response :success
    assert_select "#presentation_display"

    # Timer page loads fine
    get timer_room_url(room.passcode)
    assert_response :success
    assert_select "#timer_display"
  end

  # ══════════════════════════════════════════════════════════════════
  # Edge case: timer set_duration edge values
  # ══════════════════════════════════════════════════════════════════

  test "timer duration edge cases" do
    room = rooms(:one)

    # Negative value defaults to 60
    patch update_timer_room_url(room.passcode), params: { action_type: "set_duration", duration_str: "-5" }
    room.reload
    assert_equal 60, room.timer_duration

    # Empty string defaults to 60
    patch update_timer_room_url(room.passcode), params: { action_type: "set_duration", duration_str: "" }
    room.reload
    assert_equal 60, room.timer_duration

    # Valid MM:SS
    patch update_timer_room_url(room.passcode), params: { action_type: "set_duration", duration_str: "01:30" }
    room.reload
    assert_equal 90, room.timer_duration
    assert_equal 90, room.timer_remaining
  end

  # ══════════════════════════════════════════════════════════════════
  # Media asset renaming workflow
  # ══════════════════════════════════════════════════════════════════

  test "rename slide inline" do
    room = rooms(:one)

    # Create a real asset with file attachment first
    file = fixture_file_upload("test_image.png", "image/png")
    post room_media_assets_url(room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    asset = room.media_assets.order(created_at: :desc).first

    patch room_media_asset_url(room.passcode, asset),
      params: { media_asset: { title: "Renamed Slide" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    asset.reload
    assert_equal "Renamed Slide", asset.title
  end

  # ══════════════════════════════════════════════════════════════════
  # Verify turbo stream subscriptions are present on viewer pages
  # ══════════════════════════════════════════════════════════════════

  test "timer page subscribes to timer and message channels" do
    room = rooms(:one)
    get timer_room_url(room.passcode)
    assert_response :success
    # The page should have turbo_stream_from tags for both channels
    assert_select "turbo-cable-stream-source[signed-stream-name]", minimum: 2
  end

  test "presentation page subscribes to presentation channel" do
    room = rooms(:one)
    get presentation_room_url(room.passcode)
    assert_response :success
    assert_select "turbo-cable-stream-source[signed-stream-name]", minimum: 1
  end
end
