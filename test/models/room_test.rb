require "test_helper"

class RoomTest < ActiveSupport::TestCase
  # ── Fixture sanity ──────────────────────────────────────────────
  test "fixtures load without errors" do
    assert rooms(:one).valid?
    assert rooms(:two).valid?
  end

  # ── Validations ─────────────────────────────────────────────────
  test "requires a passcode" do
    room = Room.new(passcode: nil)
    assert_not room.valid?
    assert_includes room.errors[:passcode], "can't be blank"
  end

  test "enforces unique passcode" do
    existing = rooms(:one)
    duplicate = Room.new(passcode: existing.passcode)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:passcode], "has already been taken"
  end

  test "allows different passcodes" do
    room = Room.new(passcode: "unique-code-123")
    assert room.valid?
  end

  # ── Default values ──────────────────────────────────────────────
  test "sets default timer_duration to 600 on new records" do
    room = Room.new(passcode: "defaults-test")
    assert_equal 600, room.timer_duration
  end

  test "sets default timer_remaining to 600 on new records" do
    room = Room.new(passcode: "defaults-test")
    assert_equal 600, room.timer_remaining
  end

  test "sets default timer_status to stopped on new records" do
    room = Room.new(passcode: "defaults-test")
    assert_equal "stopped", room.timer_status
  end

  test "sets default current_slide to 1 on new records" do
    room = Room.new(passcode: "defaults-test")
    assert_equal 1, room.current_slide
  end

  test "does not override provided values with defaults" do
    room = Room.new(passcode: "custom", timer_duration: 120, timer_status: "playing", current_slide: 5)
    assert_equal 120, room.timer_duration
    assert_equal "playing", room.timer_status
    assert_equal 5, room.current_slide
  end

  test "does not overwrite defaults on persisted records" do
    room = rooms(:one)
    room.update!(timer_duration: 999)
    room.reload
    assert_equal 999, room.timer_duration
  end

  # ── Associations ────────────────────────────────────────────────
  test "has many media_assets" do
    room = rooms(:one)
    assert_respond_to room, :media_assets
  end

  test "has many presentations" do
    room = rooms(:one)
    assert_respond_to room, :presentations
  end

  test "destroys associated media_assets on destroy" do
    room = rooms(:one)
    media_count = room.media_assets.count
    assert media_count > 0, "fixture should have media assets"

    assert_difference "MediaAsset.count", -media_count do
      room.destroy
    end
  end

  test "destroys associated presentations on destroy" do
    room = rooms(:one)
    pres_count = room.presentations.count
    assert pres_count > 0, "fixture should have presentations"

    assert_difference "Presentation.count", -pres_count do
      room.destroy
    end
  end

  # ── total_slides ────────────────────────────────────────────────
  test "total_slides counts only image and video assets" do
    room = rooms(:one)
    # fixtures: slide_one (image), slide_two (image), video_one (video) = 3 slides
    assert_equal 3, room.total_slides
  end

  test "total_slides returns 0 for room with no media" do
    room = rooms(:two)
    assert_equal 0, room.total_slides
  end

  # ── current_media_asset ─────────────────────────────────────────
  test "current_media_asset returns the asset at the current slide position" do
    room = rooms(:one)
    room.update!(current_slide: 1)
    asset = room.current_media_asset
    assert_not_nil asset
    # Fixture media assets don't have Active Storage files attached,
    # so we check by media_type instead of calling .slide?
    assert_includes %w[image video], asset.media_type
  end

  test "current_media_asset returns nil when current_slide is beyond total" do
    room = rooms(:one)
    room.update!(current_slide: 100)
    assert_nil room.current_media_asset
  end

  test "current_media_asset returns nil for room with no slides" do
    room = rooms(:two)
    assert_nil room.current_media_asset
  end

  # ── current_audio ───────────────────────────────────────────────
  test "current_audio returns nil when current_audio_id is nil" do
    room = rooms(:one)
    room.update!(current_audio_id: nil)
    assert_nil room.current_audio
  end

  test "current_audio returns the audio asset when set" do
    room = rooms(:one)
    audio = media_assets(:audio_one)
    room.update!(current_audio_id: audio.id)
    assert_equal audio, room.current_audio
  end

  test "current_audio returns nil for nonexistent audio id" do
    room = rooms(:one)
    room.update!(current_audio_id: 999_999)
    assert_nil room.current_audio
  end

  # ── video_playing? ──────────────────────────────────────────────
  test "video_playing? returns false when room has no slides" do
    room = rooms(:two)
    assert_not room.video_playing?
  end
end
