require 'test_helper'

class DictPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get root" do
    get root_url
    assert_response :success
  end

  test "should get help" do
    get dict_pages_help_url
    assert_response :success
  end

  test "should get about" do
    get dict_pages_about_url
    assert_response :success
  end

  test "should get admin" do
    get dict_pages_admin_url
    assert_response :success
  end

end
