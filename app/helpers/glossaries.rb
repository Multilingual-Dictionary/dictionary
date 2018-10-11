################################################################################
###	UPDATER
################################################################################
class GlossaryUpdater
  def initialize(glossary,data)
	db_config= YAML::load(File.open('config/database.yml'))
	glossary_lib= GlossaryLib.new(
                      {
                        "host" => "localhost",
                        "username" => db_config[Rails.env]["username"],
                        "password" =>db_config[Rails.env]["password"],
                        "database" =>db_config[Rails.env]["database"]
                      })
	glossary.id=glossary_lib.update(glossary.dict_id,glossary.id,data)
	return 
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
