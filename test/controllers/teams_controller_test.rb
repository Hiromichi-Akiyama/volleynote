require "test_helper"

class TeamsControllerTest < ActionDispatch::IntegrationTest
  test "should get settings" do
    get teams_settings_url
    assert_response :success
  end
end
