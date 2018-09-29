class DictPagesController < ApplicationController

  ###
  ###  ADD New entry for glossary ( not admin user )
  ###
  def dict_add
	printf("dict-add\n")
	@dict_id="mydict"
	@lang_codes=Dictionaries.new([]).lang_codes
	printf("LANG CODES %s\n",@lang_codes)
    if params[:id]==nil or params[:id]=="" or params[:id]=="0"
		my_glossary_new()
	else
		my_glossary_update()
	end
  end
  ###
  ###  NEW
  ###
  
  def my_glossary_new
	params[:id]=="0"
	@data=Hash.new
	## get data from params
	params.each{|f,v|
		next if f[0] != "#"
		@data[f]=v
	}
	@fields=nil
	if @data.size!= 0
		@fields=GlossaryUtils.new.build_template_fields(@data,@lang_codes)
	else
		### data empty
		### build new from config
		###	
		@fields=Hash.new
		if nil != get_dict_config(@dict_id)
			printf("DictConfig %s\n",@dict_config.inspect())
			lang_cfg=get_languages_config(@dict_config)
			printf("LangConfig %s\n",lang_cfg.inspect())
			@fields=GlossaryUtils.new.build_template_fields(lang_cfg,@lang_codes)
		end
	end
	printf("FIELDS %s\n",@fields.inspect())
	case params[:commit]
	when "Tạo"
		glossary=Glossary.new
		glossary.dict_id=@dict_id.upcase
		updater= GlossaryUpdater.new(glossary,@data)
		params[:id]=glossary.id
	else
	
	end
  end
  
  def my_glossary_update()
	@fields=Hash.new
	printf("MY GLOSSARY UPDATE  %d\n",params[:id])
	begin
		glossary=Glossary.find(params[:id])
	rescue
		glossary=nil
		warn(sprintf("Không tìm thấy từ mục %s",params[:id]))
		return
	end
	if glossary==nil
		warn(sprintf("Không tìm thấy từ mục %s",params[:id]))
		return
	end
	if @dict_id.upcase != glossary.dict_id.upcase
		warn(sprintf("Không đúng tự điển %s,%s",glossary.dict_id,@dict_id))
		return 
	end
	@data = json_parse(glossary.data)
	if @data == nil
		@fields=Hash.new
		return
	end
	@fields=GlossaryUtils.new.build_template_fields(@data,@lang_codes)
	case params[:commit]
	when "Thay đổi"
		update_it(glossary)
	else
	end
	if @fields.size==0
		warn("Tự điển chưa được cấu hình đúng")
	end
  end
  def update_it(glossary)
	## @fields 
	changed=false
	params.each{|f,v|
		next if f[0] != "#"
		if v != @data[f]
			changed= true
		end

		if v != @data[f]
			changed= true
			@data[f]=v
		end
	}
	return if not changed
	updater= GlossaryUpdater.new(glossary,@data)
  end
  
  
end