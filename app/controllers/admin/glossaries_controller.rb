class AdminPagesController < ApplicationController

################################################################################
##### Common utils
################################################################################

  #####################################################################
  def warn(txt)
	@warning='' if @warn==nil
	@warning << txt
  end
  def build_head(data)
    	fields = Hash.new
	return fields if data==nil
	head=Hash.new
	terms=Hash.new
	explains=Hash.new
	anothers=Hash.new
	data.each{|tag,v|
		pos = tag.index(":")
        	if pos == nil
			tag_key=tag
			tag_lang=""
		else
			tag_key=tag[0,pos]
			tag_lang= tag[pos+1,2]
			tag_lang= "" if tag_lang==nil
		end
		next if tag_key[0,1]!="#"
		
		tag_lang=@lang_codes[tag_lang]
		if tag_lang==nil
			tag_lang = ""
		else
			tag_lang = "["+tag_lang+"]"
		end
		case tag_key
		when "#TERM"
			terms[tag]="Từ ngữ " + tag_lang
		when "#EXPLAIN"
			explains[tag]="Giải thích " + tag_lang
		when "#CATEGORY"
			anothers[tag]="Lĩnh vực " + tag_lang
        when "#GRAMMAR"
			anothers[tag]="Từ loại " + tag_lang
        else
			anothers[tag]=tag_key + tag_lang
        end
	}
	fields = Hash.new
	terms.each{|t,v|
		fields[t]=v
	}
	explains.each{|t,v|
		fields[t]=v
	}
	anothers.each{|t,v|
		fields[t]=v
	}
	return fields
  end
  #################################################################
  def json_parse(data)
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
  def get_languages_config(dict_config)
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
  
################################################################################
##### GLOSSARIES
################################################################################
  def glossaries
	printf("GLOSSARIE\n")
	@glossaries = Hash.new
	err = init_glossaries()
	@fields=build_head(@lang_cfg)
	if @dict_id!=nil and params[:to_search] != nil and params[:to_search] != ''  
		conn = ActiveRecord::Base.connection	
		query = "select distinct  item_id from glossary_indices where dict_id=#{conn.quote(@dict_id)}"
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
	else
	
	end
	
  end
end
################################################################################
###	UPDATER
################################################################################
class GlossaryUpdater
  def initialize(glossary,data)
    @dict_id=glossary.dict_id
	@index = ""
	## build Hash & Json
	md5 = Digest::MD5.new
    md5 << @dict_id.upcase
	data.each{|tag,v|
		v = "" if  v==nil
        v.strip!
		md5 << v.upcase
    }
    @item_id= md5.hexdigest
	json = JSON.generate(data)
	## build indices
	data.each{|k,v|
		next if k.index("TERM:")==nil
        add_index(k[6,2],v) if v !=""
	}
	glossary.data=json
	old_item_id=glossary.item_id
	glossary.item_id=@item_id
	insert_indices= "insert into glossary_indices "+
	                "(dict_id,lang,item_id,key_words,key_len,created_at," +
					"updated_at)values\n" +
					@index
					

	
	conn = ActiveRecord::Base.connection
    res = conn.select_all(
		sprintf("delete from glossary_indices where item_id='%s'\n",old_item_id))
	conn.select_all(insert_indices)
	glossary=nil if glossary.id=="" or glossary.id=="0"
	glossary.save
  end
  def remove_notes(txt,open,close)
	is_in = false
	res = ""
	txt.each_char{|c|
		if c==open
			is_in = true
			next
		end
		if c == close
			is_in = false
			next
		end
		if not is_in
			res << c
		end
	}
	return res
 end
 def add_index(lang,key_words)
    ##printf("add index %s,%s,%s,%s\n",lang,key_words,@dict_id,@item_id)
	key_words=remove_notes(key_words,"(",")")
	key_words=remove_notes(key_words,"{","}")
	key_words=remove_notes(key_words,"[","]")
	return if key_words==""
	conn = ActiveRecord::Base.connection		
	key_words.gsub(/;/,",").split(',').each{|key|
		####printf("KEY %s\n",key)
		key.strip!
		next if key==""
		if key.length>250
			next
		end
		@index << ",\n" if @index.length>0

        @index << sprintf("(%s,'%s','%s',%s,'%d',now(),now())\n",
			conn.quote(@dict_id),
            lang,
            @item_id,
            conn.quote(key),
            key.length)
	}
  end
end
  
