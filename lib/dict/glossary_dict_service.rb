require_relative 'dict_service'

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
	indices[r.digest]=r
    }
    #######
    digests = ""
    indices.each{|digest,r|
        digests << "," if  digests != ""
	digests << "'" << digest << "'"
    }
    
    ### nothing found!
    return result() if digests == ""

    ### For the digests search for all translated-keywords related

    results = GlossaryIndex.find_by_sql(sprintf(
      "select * from glossary_indices where digest in (%s) ",digests))
    xlated = Hash.new
    results.each(){|r|
      if not xlated.has_key?(r.digest)
         xlated[r.digest]=Hash.new
      end
      if not xlated[r.digest].has_key?(r.lang)
         xlated[r.digest][r.lang]=[]
      end
      xlated[r.digest][r.lang]<<r.key_words
    }
    ### now we have all translated-keywords in xlated!


    ### For the digests search for all dictionary-entries related
    
    results = Glossary.find_by_sql(sprintf(
		"select * from glossaries where digest in (%s) ",digests))

    results.each(){|r|   ### each entry

      cfg= @cfg[r.dict_id.upcase]
      key_words = indices[r.digest].key_words
      key_lang = indices[r.digest].lang
      translated = Hash.new
      xlated_word= Hash.new
      attr = ''
      if key_lang==cfg["ext_cfg"]["key_words_lang"]
        translated[cfg["ext_cfg"]["primary_xlate_lang"]]=r.primary_xlate
        translated[cfg["ext_cfg"]["secondary_xlate_lang"]]=r.secondary_xlate
        xlated_word[cfg["ext_cfg"]["primary_xlate_lang"]]= xlated[r.digest][cfg["ext_cfg"]["primary_xlate_lang"]]
        xlated_word[cfg["ext_cfg"]["secondary_xlate_lang"]]= xlated[r.digest][cfg["ext_cfg"]["secondary_xlate_lang"]]
	attr << "/" + r.word_type  if r.word_type != ""
      else
        translated[cfg["ext_cfg"]["key_words_lang"]]=r.key_words
        xlated_word[cfg["ext_cfg"]["key_words_lang"]]= xlated[r.digest][cfg["ext_cfg"]["key_words_lang"]]
         if key_lang==cfg["ext_cfg"]["primary_xlate_lang"]
            translated[cfg["ext_cfg"]["secondary_xlate_lang"]]=r.secondary_xlate
            xlated_word[cfg["ext_cfg"]["secondary_xlate_lang"]]= xlated[r.digest][cfg["ext_cfg"]["secondary_xlate_lang"]]
         else
            translated[cfg["ext_cfg"]["primary_xlate_lang"]]=r.primary_xlate
            xlated_word[cfg["ext_cfg"]["primary_xlate_lang"]]= xlated[r.digest][cfg["ext_cfg"]["primary_xlate_lang"]]
         end
      end
      attr << "/" + r.category  if r.category != ""
      attr << "/" if attr != ""
      key = key_words  
      key << " " << attr if attr != ""
      infos=Hash.new
      infos[:key_words]=key_words
      infos[:key_lang]=key_lang
      infos[:xlated_word]=xlated_word
      txt = []
      translated.each{|l,t|
         txt << t
      }
      add_entry(cfg["dict_sys_name"],key,txt,infos)
    }
    return result()
    end
end 
