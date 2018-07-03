require 'test_helper'

class ProgressBarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @progress_bar = progress_bars(:one)
  end

  test "should get index" do
    get progress_bars_url
    assert_response :success
  end

  test "should get new" do
    get new_progress_bar_url
    assert_response :success
  end

  test "should create progress_bar" do
    assert_difference('ProgressBar.count') do
      post progress_bars_url, params: { progress_bar: { message: @progress_bar.message, percent: @progress_bar.percent, user_id: @progress_bar.user_id } }
    end

    assert_redirected_to progress_bar_url(ProgressBar.last)
  end

  test "should show progress_bar" do
    get progress_bar_url(@progress_bar)
    assert_response :success
  end

  test "should get edit" do
    get edit_progress_bar_url(@progress_bar)
    assert_response :success
  end

  test "should update progress_bar" do
    patch progress_bar_url(@progress_bar), params: { progress_bar: { message: @progress_bar.message, percent: @progress_bar.percent, user_id: @progress_bar.user_id } }
    assert_redirected_to progress_bar_url(@progress_bar)
  end

  test "should destroy progress_bar" do
    assert_difference('ProgressBar.count', -1) do
      delete progress_bar_url(@progress_bar)
    end

    assert_redirected_to progress_bars_url
  end
end
