require 'test_helper'

class AdminPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get admin_home" do
    get admin_pages_admin_home_url
    assert_response :success
  end

  test "should get config_dict" do
    get admin_pages_config_dict_url
    assert_response :success
  end

  test "should get config_user" do
    get admin_pages_config_user_url
    assert_response :success
  end

end
