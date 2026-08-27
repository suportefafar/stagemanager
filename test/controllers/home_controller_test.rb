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

  test "index uses the FAFAR authentication shell" do
    get root_url
    assert_select "body[data-fafar-theme='institucional'].room-entry-page"
    assert_select "main.auth-shell#conteudo"
    assert_select ".auth-panel"
  end
end
