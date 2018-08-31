require_relative 'dict_service'
require 'json'

class GlossaryDictService < DictService 
  def initialize(cfg=nil)
    @cfg = cfg
    
  end

  ##
  ##  LOOKUP ( to_search .. )
  ##

  def lookup(to_search,dict_id="")
    lookup_init()
    conn = ActiveRecord::Base.connection
    dicts=""
    dict_id.split(",").each{|d|
      dicts << "," if dicts!=""
      dicts << conn.quote(d)
    }
    if dicts == ""
      return result() if dicts == ""
    end
  

    ### search for key_words in GLOSSARY_INDICES 
    query = "select * from glossary_indices where dict_id in (#{dicts}) "
    if @search_mode=='search_contain'
      to_search.split(' ').each{|w|
        query << " and key_words like #{conn.quote('%'+w.strip+'%')} "
      }
    else
        query << " and key_words = #{conn.quote(to_search.strip)}"
    end
    if @src_lang!='ALL'
       query << " and lang in ("
       i = 0
       @src_lang.split(",").each{|l|
         query << "," if i > 1
         i = i + 1
         query << "'" << l.strip << "'"
       }
       query << ")"
    end
    if @search_mode=='search_contain'
       query << " limit 100"
    end
    results = GlossaryIndex.find_by_sql(query)
    indices=Hash.new
    results.each(){|r|
	indices[r.item_id]=r
    }
    #######
    item_ids = ""
    indices.each{|item_id,r|
        item_ids << "," if  item_ids != ""
	item_ids << "'" << item_id << "'"
    }
    
    ### nothing found!
    return result() if item_ids == ""

    ### For the item_ids search for all translated-keywords related

    results = GlossaryIndex.find_by_sql(sprintf(
      "select * from glossary_indices where item_id in (%s) ",item_ids))
    xlated = Hash.new
    results.each(){|r|
      if not xlated.has_key?(r.item_id)
         xlated[r.item_id]=Hash.new
      end
      if not xlated[r.item_id].has_key?(r.lang)
         xlated[r.item_id][r.lang]=[]
      end
      xlated[r.item_id][r.lang]<<r.key_words
    }
    ### now we have all translated-keywords in xlated!

    printf("XLATED %s\n",xlated.inspect())


    ### For the item_ids search for all dictionary-entries related
    
    results = Glossary.find_by_sql(sprintf(
		"select * from glossaries where item_id in (%s) ",item_ids))
    results.each(){|r|   ### each dictionary-entry
      printf("RESULT %s\n",r.inspect())
      xlated_word= Hash.new
      txt = []
      attr = ""
      ##
      ## parse json-data
      ##
      begin
        entry_data=JSON.parse(r.data)
      rescue
        entry_data=Hash.new ## empty ! just in case!
      end
      printf("ENTRY %s\n",entry_data.inspect())
      ## key-words of this entry 
      key_words = indices[r.item_id].key_words
      key_lang = indices[r.item_id].lang
      printf("KEY %s,%s\n",key_words,key_lang)
      ##
      ## get xlated and another informations from entry_data
      ##
      entry_data.each{|tag,value|
        printf("TAG %s,VALUE %s\n",tag,value)
	pos = tag.index(":")
        if pos == nil
        	tag_key=tag
        	tag_lang=""
        else
        	tag_key=tag[0,pos]
        	tag_lang=tag[pos,2]
	end
        printf("TAG [%s][%s]\n",tag_key,tag_lang)
        case tag_key
        when "#TERM"
		printf("is term\n")
      		txt << value
        when "#CATEGORY"
		attr << "/" + value
        when "#GRAMMAR"
		attr << "/" + value
        else
      		txt << value
        end
      }
      attr << "/" if attr != ""
      key = key_words  
      key << " " << attr if attr != ""
      infos=Hash.new
      infos[:key_words]=key_words
      infos[:key_lang]=key_lang
      infos[:xlated_word]=xlated[r.item_id]
      add_entry(r.dict_id,key,txt,infos)
    }
    return result()
    end
end 
