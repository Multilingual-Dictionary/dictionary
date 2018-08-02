require 'test_helper'

class GlossaryIndicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @glossary_index = glossary_indices(:one)
  end

  test "should get index" do
    get glossary_indices_url
    assert_response :success
  end

  test "should get new" do
    get new_glossary_index_url
    assert_response :success
  end

  test "should create glossary_index" do
    assert_difference('GlossaryIndex.count') do
      post glossary_indices_url, params: { glossary_index: { dict_id: @glossary_index.dict_id, digest: @glossary_index.digest, key_words: @glossary_index.key_words, lang: @glossary_index.lang } }
    end

    assert_redirected_to glossary_index_url(GlossaryIndex.last)
  end

  test "should show glossary_index" do
    get glossary_index_url(@glossary_index)
    assert_response :success
  end

  test "should get edit" do
    get edit_glossary_index_url(@glossary_index)
    assert_response :success
  end

  test "should update glossary_index" do
    patch glossary_index_url(@glossary_index), params: { glossary_index: { dict_id: @glossary_index.dict_id, digest: @glossary_index.digest, key_words: @glossary_index.key_words, lang: @glossary_index.lang } }
    assert_redirected_to glossary_index_url(@glossary_index)
  end

  test "should destroy glossary_index" do
    assert_difference('GlossaryIndex.count', -1) do
      delete glossary_index_url(@glossary_index)
    end

    assert_redirected_to glossary_indices_url
  end
end
