json.extract! dict_config, :id, :dict_sys_name, :dict_name, :lang, :xlate_lang, :desc, :protocol, :url, :syntax, :ext_infos, :created_at, :updated_at
json.url dict_config_url(dict_config, format: :json)
