require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  test "should get manager" do
    get rooms_manager_url
    assert_response :success
  end

  test "should get presentation" do
    get rooms_presentation_url
    assert_response :success
  end

  test "should get timer" do
    get rooms_timer_url
    assert_response :success
  end
end
