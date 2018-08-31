class AdminPagesController < ApplicationController
	def config_dict_setup
		@dictionaries=Dictionaries.new(DictConfig.where("priority>0").order(priority: :desc))
		@notice=nil
		@warning=nil
		@protocol_options=["glossary","rfc2229","wiktionary","google"]
		@lang_options=@dictionaries.lang_codes
	end
	def delete_dict(id)
		##return "can not delete because.."
		begin
			dict=DictConfig.find(id)
		rescue
			return nil
		end
		if dict.protocol.downcase=='glossary'
			cnt=Glossary.new.count_records(dict.dict_sys_name).to_i
			if cnt > 0
				return sprintf("Tự điển %s đang có %d từ mục\n",dict.dict_name,cnt)+
						"Nếu muốn xóa thì phải xóa các từ mục trước!"
			end
		end
		dict.destroy
		return nil
	end
	def is_empty(v)
		return true if v==nil or v.strip==""
	end
	def validate(dict_config)
		return "Chưa điền tên hệ thống" if is_empty(dict_config.dict_sys_name)
		return "Chưa điền tên tự điển" if is_empty(dict_config.dict_name)
		return "Chưa điền ngôn ngữ gốc" if is_empty(dict_config.lang)
		return "Chưa điền ngôn ngữ đích" if is_empty(dict_config.xlate_lang)
		return nil
	end
	def config_dict
		printf("CFG PARAMS %s\n",params.inspect())
		config_dict_setup
		if params[:id]==nil or params[:id].strip==""
			printf("TRUE\n")
			params[:id]="0"
		else
			printf("FALSE\n")
		end
		printf("PARAMID [%s]\n",params[:id])
		if params[:id]!="0"
			begin
				@dict_config=  DictConfig.find(params[:id])
			rescue
				@dict_config=  DictConfig.new
				@dict_config.id="0"
			end
		else
			@dict_config=  DictConfig.new
			@dict_config.id="0"
		end
		if params[:dict_sys_name]==nil
			params[:dict_sys_name]=@dict_config.dict_sys_name
			params[:dict_name]=@dict_config.dict_name
			params[:lang]=@dict_config.lang
			params[:xlate_lang]=@dict_config.xlate_lang
			params[:protocol]=@dict_config.protocol
			params[:desc]=@dict_config.desc
			params[:cfg]=@dict_config.cfg
			params[:priority]=@dict_config.priority
			params[:url]=@dict_config.url
		end
		if params[:do_it]=="delete"
			params[:do_it]==""
			ret = delete_dict(params[:id])
			printf("DELETE RET %s\n",ret.inspect())
			if ret == nil
				@notice=sprintf("Đã xóa tự điển %s! \n",params[:dict_name])
				params[:dict_sys_name]="deleted"
				params[:status]="deleted"
			else
				@warning= ret
			end
		end
		if params[:commit]=="Tạo" or params[:commit]=="Thay đổi"
			@dict_config.id=params[:id].strip
			if @dict_config.id=="0"
				@dict_config.id=nil   ## create!
			end
			@dict_config.dict_sys_name=params[:dict_sys_name].strip
			@dict_config.dict_name=params[:dict_name].strip
			@dict_config.lang=params[:lang].strip
			@dict_config.xlate_lang=params[:xlate_lang].strip
			@dict_config.protocol=params[:protocol].strip
			@dict_config.priority=params[:priority].strip
			@dict_config.desc=params[:desc].strip
			@dict_config.cfg=params[:cfg].strip
			printf("AAAA %s\n",@dict_config.inspect())
			valid = validate(@dict_config)
			printf("BBBB %s\n",@dict_config.inspect())
			if valid==nil
				@dict_config.id=nil if @dict_config.id=="" or @dict_config.id=="0"
				@dict_config.save
				params[:id]=@dict_config.id
			else
				@warning= valid 
			end
		end
		@mode = "update"
	end
end
