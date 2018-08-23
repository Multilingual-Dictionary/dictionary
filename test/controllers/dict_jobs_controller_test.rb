require 'test_helper'

class DictJobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dict_job = dict_jobs(:one)
  end

  test "should get index" do
    get dict_jobs_url
    assert_response :success
  end

  test "should get new" do
    get new_dict_job_url
    assert_response :success
  end

  test "should create dict_job" do
    assert_difference('DictJob.count') do
      post dict_jobs_url, params: { dict_job: { in_data: @dict_job.in_data, job_id: @dict_job.job_id, job_name: @dict_job.job_name, message: @dict_job.message, notes: @dict_job.notes, out_data: @dict_job.out_data, percent: @dict_job.percent, stage: @dict_job.stage, status: @dict_job.status } }
    end

    assert_redirected_to dict_job_url(DictJob.last)
  end

  test "should show dict_job" do
    get dict_job_url(@dict_job)
    assert_response :success
  end

  test "should get edit" do
    get edit_dict_job_url(@dict_job)
    assert_response :success
  end

  test "should update dict_job" do
    patch dict_job_url(@dict_job), params: { dict_job: { in_data: @dict_job.in_data, job_id: @dict_job.job_id, job_name: @dict_job.job_name, message: @dict_job.message, notes: @dict_job.notes, out_data: @dict_job.out_data, percent: @dict_job.percent, stage: @dict_job.stage, status: @dict_job.status } }
    assert_redirected_to dict_job_url(@dict_job)
  end

  test "should destroy dict_job" do
    assert_difference('DictJob.count', -1) do
      delete dict_job_url(@dict_job)
    end

    assert_redirected_to dict_jobs_url
  end
end
