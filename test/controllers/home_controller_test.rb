require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index (root path)" do
    get root_url
    assert_response :success
  end

  test "index contains passcode form" do
    get root_url
    assert_select "form" do
      assert_select "input[name='passcode']"
      assert_select "input[type='submit']"
    end
  end
end
