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

class GlossaryUtils
 def build_template_fields(data,lang_codes)
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
		
		tag_lang=lang_codes[tag_lang]
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
		when "#HTML"
			anothers[tag]="HTML"
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
end