require 'test_helper'

class ExportGlossaryControllerTest < ActionDispatch::IntegrationTest
  test "should get export" do
    get export_glossary_export_url
    assert_response :success
  end

end
