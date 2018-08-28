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
		DictConfig.find(id).destroy
		return nil
	end
	def config_dict
		printf("CFG PARAMS %s\n",params.inspect())
		config_dict_setup
		if params[:id]==nil
			params[:id]=="0"
		end
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
			if ret == nil
				@notice="DELETED"
				params[:dict_sys_name]="deleted"
				params[:status]="deleted"
			else
				@warning= ret
			end
		end
		if params[:commit]=="update"
			@dict_config.id=params[:id].strip
			if @dict_config.id=="0"
				@dict_config.id=nil
			end
			@dict_config.dict_sys_name=params[:dict_sys_name].strip
			@dict_config.dict_name=params[:dict_name].strip
			@dict_config.lang=params[:lang].strip
			@dict_config.xlate_lang=params[:xlate_lang].strip
			@dict_config.protocol=params[:protocol].strip
			@dict_config.desc=params[:desc].strip
			@dict_config.cfg=params[:cfg].strip
			@dict_config.save
			params[:id]=@dict_config.id
		end
		@mode = "update"
	end
	def config_dict_new
		printf("NEW PARAMS %s\n",params.inspect())
		config_dict_setup
		@mode = "update"
		if params[:id]==nil or params[:id]==""
			@dict_config=  DictConfig.new
			@mode = "create"
			@dict_config.id=""
			@dict_config.dict_sys_name=params[:dict_sys_name]
			@dict_config.dict_name=params[:dict_sys_name]
			@dict_config.lang=params[:lang]
			@dict_config.xlate_lang=params[:xlate_lang]
			@dict_config.url=params[:url]
			@dict_config.protocol=params[:protocol]
			@dict_config.desc=params[:desc]
			@dict_config.cfg=params[:cfg]
		else
			begin
			@dict_config=  DictConfig.find(params[:id])
			rescue 
				@dict_config=  DictConfig.new
				@dict_config.dict_name=sprintf("Error! Record %s not exists!",params[:id])
				@dict_config.id=""
			end
		end
		if params[:commit]=="update" 
			ok = true
			if @mode=="create"
				rec = @dict_config.find_by_sys_name(params[:dict_sys_name])
      				if rec != nil 
					@notice= "dup name"
					ok = false
				end
			end
			if ok
				@dict_config.save
				printf("SAVED %s\n",@dict_config.id)
				params[:id]=@dict_config.id
				redirect_to admin_pages_config_dicts_path
			end
		end
	end
end
