require "test_helper"

class PresentationTest < ActiveSupport::TestCase
  # ── Fixture sanity ──────────────────────────────────────────────
  test "fixtures load without errors" do
    assert presentations(:one).persisted?
    assert presentations(:two).persisted?
  end

  # ── Associations ────────────────────────────────────────────────
  test "belongs to room" do
    pres = presentations(:one)
    assert_respond_to pres, :room
    assert_instance_of Room, pres.room
  end

  test "has attached original_file" do
    assert_respond_to Presentation.new, :original_file
  end

  test "has attached converted_pdf" do
    assert_respond_to Presentation.new, :converted_pdf
  end

  # ── Defaults ────────────────────────────────────────────────────
  test "defaults status to processing for new records" do
    pres = Presentation.new(room: rooms(:one))
    assert_equal "processing", pres.status
  end

  test "does not override provided status" do
    pres = Presentation.new(room: rooms(:one), status: "ready")
    assert_equal "ready", pres.status
  end

  test "does not reset status on persisted records" do
    pres = presentations(:two)
    assert_equal "ready", pres.status
    pres.reload
    assert_equal "ready", pres.status
  end
end
