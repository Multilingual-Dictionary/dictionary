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
	else
	
	end
  end
  
  def my_glossary_update()
	printf("MY GLOSSARY UPDATE\n")
  end
  
  
end