require 'csv'
require_relative '../jobs/export.rb'
require './app/helpers/glossaries'
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  def initialize
    super
    @languages = {"ALL"=>"Mặc định",
				  "VI"=>"Tiếng Việt",
				  "EN"=>"Tiếng Anh",
				  "DE"=>"Tiếng Đức",
				  "FR"=>"Tiếng Pháp"}
  end
  #################################################################
  def warn(txt)
	@warning='' if @warn==nil
	@warning << txt if txt != nil
  end
  #################################################################
  def json_parse(data)
	printf("JSON-PARSE\n")
		return nil if data==nil
  		begin
			data= JSON.parse(data)
			return data
		rescue Exception => e
			warn(sprintf("json error %s\n",e))
		end
		return nil
  end
  #################################################################
  ##	get dict-configuration and make it global -> @dict_config
  #################################################################
  def get_dict_config(dict_id)
	if dict_id==nil
		warn("dict_id==nil")
		return nil
	end
	begin
		@dict_config=DictConfig.find_by( dict_sys_name: dict_id)
	rescue
		warn(sprintf("dict %s not exists",dict_id))
		@dict_config=nil
	end
	return @dict_config
  end
  #################################################################
  ##  get language configuration from dict_config
  #################################################################
  def get_languages_config(dict_config)
	printf("GET LANG CONFIG\n")
  	if dict_config==nil
		printf("ERROR dict-cfg NIL")
		return nil
	end
  	ext= json_parse(dict_config.cfg)
	if ext==nil or ext["config"] ==nil or ext["config"]["languages"]==nil
		warn("Tự điển chưa được cấu hình đúng")
		return nil
	end
	return ext["config"]["languages"]
  end
  
  
end
