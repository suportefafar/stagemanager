require "test_helper"

class MediaAssetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @room = rooms(:one)
  end

  # ── CREATE ──────────────────────────────────────────────────────
  test "create uploads image file and creates media asset" do
    file = fixture_file_upload("test_image.png", "image/png")

    assert_difference "MediaAsset.count", 1 do
      post room_media_assets_url(@room.passcode), params: {
        media_asset: { files: [ file ] }
      }
    end

    assert_redirected_to media_room_path(@room.passcode)
    follow_redirect!
    assert_response :success

    new_asset = @room.media_assets.order(created_at: :desc).first
    assert_equal "image", new_asset.media_type
    assert new_asset.file.attached?
  end

  test "create uploads audio file and creates media asset" do
    file = fixture_file_upload("test_audio.wav", "audio/wav")

    assert_difference "MediaAsset.count", 1 do
      post room_media_assets_url(@room.passcode), params: {
        media_asset: { files: [ file ] }
      }
    end

    new_asset = @room.media_assets.order(created_at: :desc).first
    assert_equal "audio", new_asset.media_type
    assert new_asset.loop, "audio should default to loop=true"
  end

  test "create with multiple files creates multiple assets" do
    file1 = fixture_file_upload("test_image.png", "image/png")
    file2 = fixture_file_upload("test_image.png", "image/png")

    assert_difference "MediaAsset.count", 2 do
      post room_media_assets_url(@room.passcode), params: {
        media_asset: { files: [ file1, file2 ] }
      }
    end
  end

  # ── UPDATE ──────────────────────────────────────────────────────
  test "update changes title of a media asset with real file" do
    # Create asset with real file first (fixtures don't have Active Storage files)
    file = fixture_file_upload("test_image.png", "image/png")
    post room_media_assets_url(@room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    asset = @room.media_assets.order(created_at: :desc).first

    patch room_media_asset_url(@room.passcode, asset), params: {
      media_asset: { title: "New Title" }
    }

    asset.reload
    assert_equal "New Title", asset.title
  end

  test "update changes loop attribute with real file" do
    # Create video-type asset
    file = fixture_file_upload("test_image.png", "video/mp4")
    post room_media_assets_url(@room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    asset = @room.media_assets.order(created_at: :desc).first

    original_loop = asset.loop
    patch room_media_asset_url(@room.passcode, asset), params: {
      media_asset: { loop: !original_loop }
    }

    asset.reload
    assert_equal !original_loop, asset.loop
  end

  test "update responds with turbo_stream" do
    file = fixture_file_upload("test_image.png", "image/png")
    post room_media_assets_url(@room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    asset = @room.media_assets.order(created_at: :desc).first

    patch room_media_asset_url(@room.passcode, asset),
      params: { media_asset: { title: "Updated" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end

  # ── DESTROY ─────────────────────────────────────────────────────
  test "destroy removes a media asset" do
    file = fixture_file_upload("test_image.png", "image/png")
    post room_media_assets_url(@room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    asset = @room.media_assets.order(created_at: :desc).first

    assert_difference "MediaAsset.count", -1 do
      delete room_media_asset_url(@room.passcode, asset)
    end

    assert_redirected_to media_room_path(@room.passcode)
  end

  test "destroy reorders remaining slides" do
    # Upload two slides
    2.times do
      file = fixture_file_upload("test_image.png", "image/png")
      post room_media_assets_url(@room.passcode), params: {
        media_asset: { files: [ file ] }
      }
    end

    first_uploaded = @room.media_assets.slides.reload.first
    delete room_media_asset_url(@room.passcode, first_uploaded)

    positions = @room.media_assets.slides.reload.pluck(:position)
    assert_equal (1..positions.length).to_a, positions
  end

  test "destroy audio asset clears current_audio_id if it was playing" do
    # Upload a real audio asset
    file = fixture_file_upload("test_audio.wav", "audio/wav")
    post room_media_assets_url(@room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    audio = @room.media_assets.audios.reload.last
    @room.update!(current_audio_id: audio.id)

    delete room_media_asset_url(@room.passcode, audio)

    @room.reload
    assert_nil @room.current_audio_id
  end

  test "destroy audio asset does not affect current_audio_id if different audio playing" do
    # Upload two audio files
    2.times do
      file = fixture_file_upload("test_audio.wav", "audio/wav")
      post room_media_assets_url(@room.passcode), params: {
        media_asset: { files: [ file ] }
      }
    end

    audios = @room.media_assets.audios.reload
    playing_audio = audios.first
    other_audio = audios.last
    @room.update!(current_audio_id: playing_audio.id)

    delete room_media_asset_url(@room.passcode, other_audio)

    @room.reload
    assert_equal playing_audio.id, @room.current_audio_id
  end

  test "destroy responds with turbo_stream" do
    file = fixture_file_upload("test_image.png", "image/png")
    post room_media_assets_url(@room.passcode), params: {
      media_asset: { files: [ file ] }
    }
    asset = @room.media_assets.order(created_at: :desc).first

    delete room_media_asset_url(@room.passcode, asset),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end
end
