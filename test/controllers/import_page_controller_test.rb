require 'test_helper'

class ImportPageControllerTest < ActionDispatch::IntegrationTest
  test "should get import_glossary" do
    get import_page_import_glossary_url
    assert_response :success
  end

end
