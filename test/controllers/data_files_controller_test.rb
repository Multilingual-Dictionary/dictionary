require 'test_helper'

class DataFilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @data_file = data_files(:one)
  end

  test "should get index" do
    get data_files_url
    assert_response :success
  end

  test "should get new" do
    get new_data_file_url
    assert_response :success
  end

  test "should create data_file" do
    assert_difference('DataFile.count') do
      post data_files_url, params: { data_file: { filename: @data_file.filename, job_id: @data_file.job_id, name: @data_file.name, notes: @data_file.notes, type: @data_file.type } }
    end

    assert_redirected_to data_file_url(DataFile.last)
  end

  test "should show data_file" do
    get data_file_url(@data_file)
    assert_response :success
  end

  test "should get edit" do
    get edit_data_file_url(@data_file)
    assert_response :success
  end

  test "should update data_file" do
    patch data_file_url(@data_file), params: { data_file: { filename: @data_file.filename, job_id: @data_file.job_id, name: @data_file.name, notes: @data_file.notes, type: @data_file.type } }
    assert_redirected_to data_file_url(@data_file)
  end

  test "should destroy data_file" do
    assert_difference('DataFile.count', -1) do
      delete data_file_url(@data_file)
    end

    assert_redirected_to data_files_url
  end
end
