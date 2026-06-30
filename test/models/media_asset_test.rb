require "test_helper"

class MediaAssetTest < ActiveSupport::TestCase
  # ── Fixture sanity ──────────────────────────────────────────────
  test "slide fixtures exist and are associated" do
    assert media_assets(:slide_one).persisted?
    assert_equal rooms(:one), media_assets(:slide_one).room
  end

  # ── Validations ─────────────────────────────────────────────────
  test "requires file attachment" do
    asset = MediaAsset.new(room: rooms(:one), media_type: "image")
    assert_not asset.valid?
    assert_includes asset.errors[:file], "can't be blank"
  end

  test "is valid with file attached" do
    asset = rooms(:one).media_assets.build(media_type: "image")
    asset.file.attach(
      io: File.open(file_fixture("test_image.png")),
      filename: "test.png",
      content_type: "image/png"
    )
    assert asset.valid?
  end

  # ── Associations ────────────────────────────────────────────────
  test "belongs to room" do
    assert_respond_to media_assets(:slide_one), :room
    assert_instance_of Room, media_assets(:slide_one).room
  end

  test "has one attached file" do
    assert_respond_to media_assets(:slide_one), :file
  end

  # ── Scopes ──────────────────────────────────────────────────────
  test "slides scope returns only image and video assets" do
    room = rooms(:one)
    slides = room.media_assets.slides
    slides.each do |asset|
      assert_includes %w[image video], asset.media_type,
        "slides scope should only contain image or video"
    end
  end

  test "audios scope returns only audio assets" do
    room = rooms(:one)
    audios = room.media_assets.audios
    audios.each do |asset|
      assert_equal "audio", asset.media_type
    end
  end

  test "ordered scope returns assets in position order" do
    room = rooms(:one)
    ordered = room.media_assets.ordered.pluck(:position)
    assert_equal ordered.sort, ordered
  end

  test "slides scope returns assets ordered by position" do
    room = rooms(:one)
    positions = room.media_assets.slides.pluck(:position)
    assert_equal positions.sort, positions
  end

  # ── Callbacks ───────────────────────────────────────────────────
  test "set_position auto-assigns next position for slide assets when position is nil" do
    room = rooms(:one)
    max_position = room.media_assets.slides.maximum(:position) || 0

    asset = room.media_assets.build(media_type: "image", position: nil)
    asset.file.attach(
      io: File.open(file_fixture("test_image.png")),
      filename: "new_slide.png",
      content_type: "image/png"
    )
    asset.save!

    # BUG FOUND: set_position uses `self.position ||=` but position defaults
    # to 0 from the DB column default, so it never triggers.
    # The callback only works when position is explicitly nil.
    assert_equal max_position + 1, asset.position
  end

  test "set_position does not set position for audio assets" do
    room = rooms(:one)
    asset = room.media_assets.build(media_type: "audio")
    asset.file.attach(
      io: File.open(file_fixture("test_audio.wav")),
      filename: "music.wav",
      content_type: "audio/wav"
    )
    asset.save!

    assert_equal 0, asset.position.to_i
  end

  test "set_audio_loop_default sets loop to true for audio" do
    room = rooms(:one)
    asset = room.media_assets.build(media_type: "audio")
    asset.file.attach(
      io: File.open(file_fixture("test_audio.wav")),
      filename: "music.wav",
      content_type: "audio/wav"
    )
    asset.save!

    assert asset.loop, "audio assets should default to loop=true"
  end

  test "set_audio_loop_default does not set loop for non-audio" do
    room = rooms(:one)
    asset = room.media_assets.build(media_type: "image", position: nil)
    asset.file.attach(
      io: File.open(file_fixture("test_image.png")),
      filename: "image.png",
      content_type: "image/png"
    )
    asset.save!

    assert_not asset.loop, "image assets should not default to loop=true"
  end

  # ── Type detection methods ──────────────────────────────────────
  test "image? returns true for image content type" do
    asset = MediaAsset.new(media_type: "image")
    asset.file.attach(
      io: File.open(file_fixture("test_image.png")),
      filename: "test.png",
      content_type: "image/png"
    )
    assert asset.image?
    assert_not asset.video?
    assert_not asset.audio?
    assert asset.slide?
  end

  test "audio? returns true for audio content type" do
    asset = MediaAsset.new(media_type: "audio")
    asset.file.attach(
      io: File.open(file_fixture("test_audio.wav")),
      filename: "test.wav",
      content_type: "audio/wav"
    )
    assert asset.audio?
    assert_not asset.image?
    assert_not asset.video?
    assert_not asset.slide?
  end

  test "slide? returns true for image or video" do
    img = MediaAsset.new(media_type: "image")
    img.file.attach(io: File.open(file_fixture("test_image.png")), filename: "i.png", content_type: "image/png")
    assert img.slide?

    vid = MediaAsset.new(media_type: "video")
    vid.file.attach(io: File.open(file_fixture("test_image.png")), filename: "v.mp4", content_type: "video/mp4")
    assert vid.slide?
  end
end
