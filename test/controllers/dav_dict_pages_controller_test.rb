require 'test_helper'

class DavDictPagesControllerTest < ActionDispatch::IntegrationTest
  test "should get import" do
    get dav_dict_pages_import_url
    assert_response :success
  end

  test "should get show" do
    get dav_dict_pages_show_url
    assert_response :success
  end

end
