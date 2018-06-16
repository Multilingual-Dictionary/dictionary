require 'test_helper'

class DavkhktDictsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @davkhkt_dict = davkhkt_dicts(:one)
  end

  test "should get index" do
    get davkhkt_dicts_url
    assert_response :success
  end

  test "should get new" do
    get new_davkhkt_dict_url
    assert_response :success
  end

  test "should create davkhkt_dict" do
    assert_difference('DavkhktDict.count') do
      post davkhkt_dicts_url, params: { davkhkt_dict: { category: @davkhkt_dict.category, english: @davkhkt_dict.english, key_words: @davkhkt_dict.key_words, type: @davkhkt_dict.type, viet: @davkhkt_dict.viet } }
    end

    assert_redirected_to davkhkt_dict_url(DavkhktDict.last)
  end

  test "should show davkhkt_dict" do
    get davkhkt_dict_url(@davkhkt_dict)
    assert_response :success
  end

  test "should get edit" do
    get edit_davkhkt_dict_url(@davkhkt_dict)
    assert_response :success
  end

  test "should update davkhkt_dict" do
    patch davkhkt_dict_url(@davkhkt_dict), params: { davkhkt_dict: { category: @davkhkt_dict.category, english: @davkhkt_dict.english, key_words: @davkhkt_dict.key_words, type: @davkhkt_dict.type, viet: @davkhkt_dict.viet } }
    assert_redirected_to davkhkt_dict_url(@davkhkt_dict)
  end

  test "should destroy davkhkt_dict" do
    assert_difference('DavkhktDict.count', -1) do
      delete davkhkt_dict_url(@davkhkt_dict)
    end

    assert_redirected_to davkhkt_dicts_url
  end
end
