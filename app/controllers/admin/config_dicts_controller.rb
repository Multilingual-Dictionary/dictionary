require './lib/dict/dictionaries_list_export'

class AdminPagesController < ApplicationController
  def config_dicts
	require_role("ADMIN")
	if params[:todo] == "export_list"
		export_list()
	end
	if params[:dict_name] != nil and  params[:dict_name] != ""
		printf("---\n")
		@dict_configs = DictConfig.where(
			"dict_name like ?","%"+params[:dict_name]+"%").
				order(priority: :desc, dict_name: :asc) 
	else
		@dict_configs = DictConfig.order(priority: :desc, dict_name: :asc) 
    	end
  end
  def export_list
        db_config= YAML::load(File.open('config/database.yml'))
	exp=DictionaryListExport.new(
		{"host" =>"localhost",
                 "username" => db_config[Rails.env]["username"],
                 "password" =>db_config[Rails.env]["password"],
                 "database" =>db_config[Rails.env]["database"]
		})
	exp.do_export("/tmp/danh_sach_tu_dien.xlsx")
	send_file "/tmp/danh_sach_tu_dien.xlsx"
  end
end
