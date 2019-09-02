require 'test_helper'

class ContestControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get contest_index_url
    assert_response :success
  end

  test "should get show" do
    get contest_show_url
    assert_response :success
  end

end
