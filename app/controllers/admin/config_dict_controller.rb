class AdminPagesController < ApplicationController
	def config_dict_setup
		@dictionaries=Dictionaries.new(DictConfig.where("priority>0").order(priority: :desc))
		@notice=nil
		@warning=nil
		@protocol_options=["glossary","rfc2229","wiktionary","google"]
		@lang_options=@dictionaries.lang_codes
	end
	def build_lang(dict_config)
		dict_config.lang=""
		dict_config.xlate_lang=""
		cfg=json_parse(dict_config.cfg)
		if cfg == nil
			printf("NIL\n")
			return true
		end
		printf("CFG %s\n",cfg.inspect())
		if cfg["config"]==nil or cfg["config"]["languages"]==nil
			printf("NOT EXIST\n")
			return true
		end
		src_lang=Hash.new
		tgt_lang=Hash.new
		cfg["config"]["languages"].each{|tag,v|
			src_term=true
			tgt_term=true
			case v.upcase
			when "T"
				src_term=false
			when "S"
				tgt_term=false
			end
			if tag[0,6]=="#TERM:"
				lang=tag[6,2].upcase
				src_lang[lang]=1 if src_term
				tgt_lang[lang]=1 if tgt_term
				next
			end
			if tag[0,9]=="#EXPLAIN:"
				lang=tag[9,2].upcase
				tgt_lang[lang]=1
				next
			end
		}
		s = ""
		src_lang.each{|l,v|
			s << "," if s != ""
			s << l
		}
		t = ""
		tgt_lang.each{|l,v|
			t << "," if t != ""
			t << l
		}
		dict_config.lang=s
		dict_config.xlate_lang=t
	end
	def set_params()
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
				printf("DICT %s\n",@dict_config.inspect())
				build_lang(@dict_config)
				printf("DICT AFTER %s\n",@dict_config.inspect())
			rescue
				printf("RESCUE !\n")
				@dict_config=  DictConfig.new
				@dict_config.id="0"
			end
		else
			@dict_config=  DictConfig.new
			@dict_config.id="0"
		end
		if params[:dict_sys_name]==nil
			set_params()
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
			if params[:commit]=="Tạo"
				@dict_config.id = nil
			end
			@dict_config.dict_sys_name=params[:dict_sys_name].strip
			@dict_config.dict_name=params[:dict_name].strip
			@dict_config.protocol=params[:protocol].strip
			@dict_config.priority=params[:priority].strip
			@dict_config.desc=params[:desc].strip
			@dict_config.cfg=params[:cfg].strip
			build_lang(@dict_config)
			set_params()
			valid = validate(@dict_config)
			if valid==nil
				@dict_config.save
				params[:id]=@dict_config.id
			else
				@warning= valid 
			end
		end
		@mode = "update"
	end
end
