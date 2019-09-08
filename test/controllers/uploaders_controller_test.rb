require 'test_helper'

class CreatorsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get uploaders_show_url
    assert_response :success
  end

end
