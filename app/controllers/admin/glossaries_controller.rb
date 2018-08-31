class AdminPagesController < ApplicationController
  #
  # First Init , return error string or nil
  #
  def init_var
	@all_glossaries_configs = []
	@dict_id = params[:dict_id]
	DictConfig.all().each {|d|
		if d.protocol=='glossary' 
			@all_glossaries_configs << d
			@dict_id = d['dict_sys_name'] if @dict_id == nil
		end
	}
	@lang_codes=Dictionaries.new([]).lang_codes
	printf("LANGCODE %s\n",@lang_codes.inspect())
	params[:dict_id] = @dict_id 
	@key_lang  = "?"
	@prim_lang  = "?"
	@sec_lang  = "?"
	@dict_name  = "?"
	@dict_id  = nil
	@dict_config=nil
	if params[:dict_id]==nil
		return
	end
	@dict_config=DictConfig.find_by( dict_sys_name: params[:dict_id])
		puts("dict_config"+@dict_config.inspect())
		if @dict_config==nil
			return
		end
		puts("OK")
		begin
			@dict_ext_cfg = JSON.parse(@dict_config.cfg)
			rescue Exception => e
		return 
	end
	puts(@dict_config.inspect)
	@dict_name  = @dict_config.dict_name
	@key_lang  = @dict_ext_cfg['config']['key_words_lang']
	@prim_lang = @dict_ext_cfg['config']['primary_xlate_lang']
	@sec_lang  = @dict_ext_cfg['config']['secondary_xlate_lang']
	@dict_id= params[:dict_id]
	return 
  end

  def glossaries
	@glossaries = []
	err = init_var()
	if(@dict_id!=nil)
		if params[:to_search] == nil or 
		   params[:to_search] == '' 
		   @glossaries = Glossary.where(
		   			  [ "dict_id = :dict_id ",
				{ dict_id: @dict_id } ] ).limit(100)
		else
		   @glossaries = Glossary.where(
			  [ "dict_id = :dict_id and key_words = :key_words ",
				{ dict_id: @dict_id , key_words: params[:to_search] } ] )
		end
	end
  end
 
  def glossary_edit
	printf("EDIT %s\n",params[:id])
  end

end
