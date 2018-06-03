require 'test_helper'

class DictConfigsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dict_config = dict_configs(:one)
  end

  test "should get index" do
    get dict_configs_url
    assert_response :success
  end

  test "should get new" do
    get new_dict_config_url
    assert_response :success
  end

  test "should create dict_config" do
    assert_difference('DictConfig.count') do
      post dict_configs_url, params: { dict_config: { desc: @dict_config.desc, dict_name: @dict_config.dict_name, dict_sys_name: @dict_config.dict_sys_name, ext_infos: @dict_config.ext_infos, lang: @dict_config.lang, protocol: @dict_config.protocol, syntax: @dict_config.syntax, url: @dict_config.url, xlate_lang: @dict_config.xlate_lang } }
    end

    assert_redirected_to dict_config_url(DictConfig.last)
  end

  test "should show dict_config" do
    get dict_config_url(@dict_config)
    assert_response :success
  end

  test "should get edit" do
    get edit_dict_config_url(@dict_config)
    assert_response :success
  end

  test "should update dict_config" do
    patch dict_config_url(@dict_config), params: { dict_config: { desc: @dict_config.desc, dict_name: @dict_config.dict_name, dict_sys_name: @dict_config.dict_sys_name, ext_infos: @dict_config.ext_infos, lang: @dict_config.lang, protocol: @dict_config.protocol, syntax: @dict_config.syntax, url: @dict_config.url, xlate_lang: @dict_config.xlate_lang } }
    assert_redirected_to dict_config_url(@dict_config)
  end

  test "should destroy dict_config" do
    assert_difference('DictConfig.count', -1) do
      delete dict_config_url(@dict_config)
    end

    assert_redirected_to dict_configs_url
  end
end
