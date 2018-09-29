class AdminPagesController < ApplicationController

################################################################################
##### Common utils
################################################################################

  #####################################################################
  def build_head(data)
	return GlossaryUtils.new.build_template_fields(data,@lang_codes)
  end
  #################################################################
  def get_records(item_ids)
	fields=Hash.new
	results = Glossary.find_by_sql(sprintf(
		"select * from glossaries where item_id in(%s)",item_ids))
	results.each{|r|
		data= json_parse(r.data)
		next if data ==nil
		@glossaries[r.id]=data
		data.each{|f,v|
			fields[f]=1
		}
	}
	@fields=build_head(fields)
  end

  
################################################################################
##### GLOSSARIES
################################################################################
  def glossaries
	require_role("ADMIN")
	if params[:do_it]!= nil and params[:do_it]=="delete" and params[:dict_id] != nil 
		conn = ActiveRecord::Base.connection	
    		conn.select_all(
			sprintf("delete from glossary_indices where dict_id=%s\n",conn.quote(params[:dict_id])))
    		conn.select_all(
			sprintf("delete from glossaries where dict_id=%s\n",conn.quote(params[:dict_id])))
	end
	@glossaries = Hash.new
	err = init_glossaries()
	@fields=build_head(@lang_cfg)
	if @dict_id!=nil and params[:to_search] != nil   
		conn = ActiveRecord::Base.connection	
		query = "select distinct  item_id from glossary_indices where dict_id=#{conn.quote(@dict_id)}"
		if params[:to_search]== ""
			params[:to_search]="*"
		end
		words=params[:to_search].gsub("*","%").gsub(" ","")
  		if words.length > 0
			query << " and key_words like #{conn.quote(words)} limit 10 "
			results = GlossaryIndex.find_by_sql(query)
			item_ids=""
			results.each{|r|
				item_ids << "," if item_ids != ""
				item_ids << "'" + r.item_id + "'"
			}
			if item_ids != ""
				get_records(item_ids)
			end
		end
	end
	if @fields.size==0
		warn("Tự điển chưa được cấu hình đúng")
	end
  end
  def get_all_glossaries_configs() 
	@all_glossaries_configs = []
	DictConfig.all().each {|d|
		if d.protocol=='glossary' 
			@all_glossaries_configs << d
			@dict_id = d['dict_sys_name'] if @dict_id == nil
		end
	}
  end
  #
  # Init , return error string or nil
  #
  def init_glossaries
	@dict_id = params[:dict_id]
	@lang_cfg= nil 
	@fields = nil
  	get_all_glossaries_configs() 
	@lang_codes=Dictionaries.new([]).lang_codes
	params[:dict_id] = @dict_id 
	@dict_id  = nil
	@dict_config=nil
	if params[:dict_id]==nil
		return
	end
	@dict_config=DictConfig.find_by( dict_sys_name: params[:dict_id])
		if @dict_config==nil
			return
		end
		begin
			ext= JSON.parse(@dict_config.cfg)
			if ext != nil and ext["config"] != nil and ext["config"]["languages"]!= nil
				@lang_cfg= ext["config"]["languages"]
			end
			rescue Exception => e
		return 
	end
	@dict_name  = @dict_config.dict_name
	@dict_id= params[:dict_id]
	return 
  end
################################################################################
##### GLOSSARY EDIT
################################################################################
  
  def glossary_edit
	@lang_codes=Dictionaries.new([]).lang_codes
    if params[:id]==nil or params[:id]=="" or params[:id]=="0"
		glossary_new()
	else
		if params[:do_it]=="delete"
			glossary_delete()
		else
			glossary_update()
		end
	end
  end
  
  ###
  ###  DELETE
  ###
  def glossary_delete
  	params["data_deleted"]="1"
	@fields=Hash.new
	begin
		glossary=Glossary.find(params[:id])
	rescue
		return
	end
	params[:dict_id]=glossary.dict_id
	conn = ActiveRecord::Base.connection
    res = conn.select_all(
		sprintf("delete from glossary_indices where item_id='%s'\n",glossary.item_id))
    res = conn.select_all(
		sprintf("delete from glossaries where id='%s'\n",glossary.id))	
  end
  ###
  ###  UPDATE
  ###
  def glossary_update
	begin
		glossary=Glossary.find(params[:id])
	rescue
		glossary=nil
		@fields=Hash.new
		return
	end
	if glossary==nil
		@fields=Hash.new
		return
	end
	params[:dict_id]=glossary.dict_id
	
	@data = json_parse(glossary.data)
	if @data == nil
		@fields=Hash.new
		return
	end
	@fields=build_head(@data)
	params[:dict_id] = glossary.dict_id
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
  ###
  ###  NEW
  ###
  def glossary_new
	params[:id]=="0"
	@data=Hash.new
	## get data from params
	params.each{|f,v|
		next if f[0] != "#"
		@data[f]=v
	}
	if @data.size!= 0
		@fields=build_head(@data)
	else
		### data empty
		### build new from config
		###
		@fields=Hash.new
		if nil != get_dict_config(params[:dict_id])
			lang_cfg=get_languages_config(@dict_config)
			@fields=build_head(lang_cfg)
		end
	end
	case params[:commit]
	when "Tạo"
		glossary=Glossary.new
		glossary.dict_id=params[:dict_id].upcase
		updater= GlossaryUpdater.new(glossary,@data)
		params[:id]=glossary.id
	else
	
	end
	
  end
end

  
