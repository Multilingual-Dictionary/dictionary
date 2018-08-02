require "./lib/dict/rfc2229_dict_service"
require "./lib/dict/glossary_dict_service"
require "./lib/dict/wiktionary_dict_service"
require 'whitesimilarity'

class Dictionaries

  def initialize(dict_infos)
    @search_mode='search_exact'
    @search_key=nil

    @dict_infos=Hash.new

    dict_infos.each{|inf|

      if inf.cfg != ""
        begin 
          tmp = JSON.parse(inf.cfg)
	  ext_cfg = tmp["config"]
        rescue
          ext_cfg = Hash.new
        end
      else
          ext_cfg = Hash.new
      end
 
      @dict_infos[inf.dict_sys_name.upcase]=
        {
          "dict_sys_name" => inf.dict_sys_name,
          "dict_name" => inf.dict_name,
          "protocol" => inf.protocol,
          "url" => inf.url,
          "ext_cfg" => ext_cfg,
          "src_languages" => to_set_of(inf.lang),
          "tgt_languages" => to_set_of(inf.xlate_lang)
        }
    }
    puts(@dict_infos)
  end

  def to_set_of(txt)
    s = []
    txt.upcase.split(",").each{|l|
      s << l.strip
    }
    return s
  end

  def dict_infos()
    return @dict_infos
  end

  def set_search_mode(mode='search_exact')
    @search_mode = mode
  end
  def set_search_key(key=nil)
    @search_key = key
  end
  
  def dict_infos_by_sys_name(name)
    return @dict_infos[name.upcase]
  end
  def dict_name(sys_name)
    inf =  @dict_infos[sys_name.upcase]
    return inf["dict_name"] if inf != nil
    return sys_name
  end
  ###################################################################
  ###########    PROCESS RESULT  ####################################
  ###################################################################
  ##
  ## parse key -> key_words and attributes 
  ##   [ only if the dict service did not do it!
  def process_key(entry)
      if not entry[:infos].has_key?("key_words")
        key=entry[:key]
        index = nil
        ['[',']','/','\\','{','}','(',')'].each{|a|
	  idx = key.index(a.to_s) 
	  if idx != nil 
		if index == nil or idx < index 
			index = idx 
		end
	  end	
        }
        if index == nil
          attr = ""
        else
          attr = key[index,key.length]
          key  = key[0,index]
        end
        entry[:infos][:key_words]=key.strip
        entry[:infos][:key_attr]=attr.strip
      end
      entry[:infos][:key_attr]="" if entry[:infos][:key_attr]==nil
      entry[:infos][:key_similarity] = WhiteSimilarity.similarity(@search_key,entry[:infos][:key_words])
  end
  def tokenize(txt)
     return []  if txt == nil
     return txt.gsub(/;/,",").split(',')
  end
  def process_xlate(dict_infos,entry)
printf("Process Xlate %s\n",entry.inspect())
return ## TODO
    xlate_lang=dict_infos.xlate_lang.upcase
    lang = dict_infos.lang.upcase
    return if xlate_lang == lang ## only one language!
    begin 
      dict_ext_cfg = JSON.parse(dict_infos.cfg)
    rescue
      dict_ext_cfg = nil
    end
    if dict_ext_cfg != nil
       primary_xlate_lang= dict_ext_cfg["config"]["primary_xlate_lang"]
       secondary_xlate_lang= dict_ext_cfg["config"]["secondary_xlate_lang"]
    else 
       primary_xlate_lang= xlate_lang
       secondary_xlate_lang= ""
    end
    entry[:infos][:xlate]=Hash.new
    entry[:infos][:xlate][primary_xlate_lang]=[]
    entry[:infos][:xlate][secondary_xlate_lang]=[]
    if entry[:infos][:primary_xlate] != nil or
       entry[:infos][:secondary_xlate] != nil 
       ## get xlate from infos
       tokenize(entry[:infos][:primary_xlate]).each{|tk|
         tk = tk.strip
         next if tk == ""
         entry[:infos][:xlate][primary_xlate_lang]<<tk
       }
       tokenize(entry[:infos][:secondary_xlate]).each{|tk|
         tk = tk.strip
         next if tk == ""
         entry[:infos][:xlate][secondary_xlate_lang]<<tk
       }
    else
       ## get xlate from text
       txts = entry[:text]
       if txts != nil
         txts.each{|txt|
           tokenize(txt).each{|tk|
             tk = tk.strip
             next if tk == ""
             entry[:infos][:xlate][primary_xlate_lang]<<tk
           }
         }
        end
    end
  end
  ##
  ## process result -> infos Hash
  ## 
  def process_result(dict_infos, result)
	return result if result.length==0
	processed=[]
	result.each{|r|
	  r[:entries].each{|e|
            if e[:infos] == nil
		e[:infos] = Hash.new
	    end
  	    process_key(e)
  	    process_xlate(dict_infos,e)
	  }
	}
	return result
  end
  #################################################################
  ###########    LOOKUP ###########################################
  #################################################################

  ##
  ##  Call dict-servce to looup now!
  ##
  def lookup(to_search,dict_infos,src_lang,tgt_lang)
    puts("LOOKUP INFOS ")
    
    puts(dict_infos.inspect())
    printf("LOOKUP USING DICT %s src_lang %s tgt_lang %s\n", dict_infos["dict_sys_name"],src_lang,tgt_lang)
    ##printf("LOOKUP USING PROTOCOL %s\n", dict_infos["protocol"].upcase )
    case dict_infos["protocol"].upcase
    when "RFC2229"
      service= RFC2229DictService.new()
    when "GLOSSARY"
      service= GlossaryDictService.new(dict_infos)
    when "WIKTIONARY"
      service= WiktionaryDictService.new(dict_infos)
    else
      ##puts("NOT SUPPORTED")
      return []
    end
   service.set_search_mode(@search_mode)
   service.set_search_key(to_search)
   service.set_languages(src_lang,tgt_lang)
   return process_result(dict_infos,
		service.lookup(to_search,dict_infos["dict_sys_name"]))
  end

  ##
  ##  using many dictionaries .. do lookup
  ##
  def lookup_using_dicts(to_search,dicts,src_lang,tgt_lang)
    ret = []
    dicts.each{|n|
      inf = dict_infos_by_sys_name(n)
      if inf != nil
        res = lookup(to_search,inf,src_lang,tgt_lang)
        if res != nil 
          res.each{|tmp|
            ret << tmp
          }
        end
      end
    }
    return ret
  end
  ##
  ##  using one dictionary .. do lookup
  ##
  def lookup_using_dict(to_search,dict,src_lang="ALL",tgt_lang="ALL")
    return lookup_using_dicts(to_search,[dict],src_lang,tgt_lang)
  end
  ##
  ##  lookup by languages
  ##    check what lang is supported , use it if matched
  ##

  def lang_matched(lang_supported, lang )
    lang = lang.upcase.strip
    return true if lang == "ALL"
    lang_supported.each{|l|
      return true if l.strip==lang
    }
    return false
  end

  def lookup_by_lang(to_search,src_lang,tgt_lang)
    dicts =  []
    @dict_infos.each { |k,inf|
	if lang_matched(inf["src_languages"],src_lang) and 
           lang_matched(inf["tgt_languages"],tgt_lang)
          dicts << inf["dict_sys_name"]
        end
    }
    return lookup_using_dicts(to_search,dicts,src_lang,tgt_lang)
  end
  #################################################################
  ###########    GET-KEY-WORDS ####################################
  #################################################################
  def get_key_words(result)
    return [] if result==nil
    k = Hash.new
    scores=[]
    result.each(){|r|
      r[:entries].each{|entry|
	key=entry[:infos][:key_words]
	k_up=key.upcase
	next if k.has_key?(k_up)
	k[k_up]=1
        scores<< [key,entry[:infos][:key_similarity]]
      }
    }
    sorted = scores.sort{|p1,p2| p2[1]<=>p1[1]}
    ret = []
    sorted.each{|i|
	ret << i[0]
    }
    return ret
  end
  #################################################################
  ###########    GET-TRANSLATED-WORDS #############################
  #################################################################
  def get_translated_words(result)
printf("GET-TRANSLATED %s\n",result.inspect())
    translated=Hash.new
    return translated if result==nil
    result.each(){|r|
      r[:entries].each{|entry|
        next if entry[:infos] == nil
        next if entry[:infos][:xlated_word]==nil
printf("GET-TRANSLATED-XLATED %s\n",entry[:infos][:xlated_word].inspect())
        entry[:infos][:xlated_word].each{|lang,xl|
          next if xl == nil
	  if translated[lang] == nil
            translated[lang]=Hash.new
          end
	  xl.each{|x|
            x_u = x.upcase + entry[:infos][:key_words].upcase 
            if translated[lang][x_u]==nil
              translated[lang][x_u]={
                "xlate"  =>x,
                "dict"   => [r[:dict_name]],
                "simi"   => entry[:infos][:key_similarity],
				"key"   => entry[:infos][:key_words]
              }
            else
              exists=false
              translated[lang][x_u]["dict"].each{|dn|
                if dn == r[:dict_name]
                  exists=true
                end
              }
              if not exists
	        simi = entry[:infos][:key_similarity]
	        translated[lang][x_u]["simi"]= simi if translated[lang][x_u]["simi"] < simi
                translated[lang][x_u]["simi"] += entry[:infos][:key_similarity]
                translated[lang][x_u]["dict"] << r[:dict_name]
              end
            end
          }
	}
      }
    }
    return sorted_translated(translated)
  end
  def sort_it(lang,xlate)
     scores=[]
     xlate.each(){|x_hash,x|
        scores<< [x_hash,x["simi"]]
     }
     sorted = scores.sort{|p1,p2| p2[1]<=>p1[1]}
     sorted_xlate = []
     sorted.each{|s|
        sorted_xlate << xlate[s[0]]
     }
     return sorted_xlate
  end
  def sorted_translated(unsorted)
    sorted = Hash.new
    unsorted.each{|lang,xlate|
      next if lang==""
      sorted[lang]=sort_it(lang,xlate)
    }
    return sorted
  end
  #################################################################
  ###########    RENDER ###########################################
  #################################################################
  def render_result(result)
    html = ""
    result[:entries].each{|entry|

      key = entry[:infos][:key_words]
      attr= entry[:infos][:key_attr]

      html << '<div >'
      html << '<p class="dict_key">'
      html <<  "<b>" << key.html_safe  << "</b>"
      html <<  "&nbsp;<i>" << attr.html_safe << "</i>"  if attr != ""
      html << '</p>'
      html << '<ul>'
      entry[:text].each{|t|
        html << '<li><p class=dict_text>'
	html << t.sub(/>/,"]").sub(/</,"[").html_safe 
	html << '</p></li>'
      }
      html << '</ul>'
      html << '</div>'
    }
    return html
  end
  def get_dict_name(short_name)
    @dict_infos.each(){|n,inf|
	  if inf["dict_sys_name"] == short_name
	    return inf["dict_name"]
	  end
	}
	return short_name
  end
  def show_dicts(dicts)
    html = "<select>"
	dicts.each{|d|
		html << sprintf('<option value="%s">%s</option>',d,get_dict_name(d))
	}
	html << "</select>"
	return html
  end
  def render_summary(result)
    if result.length == 0
       return "Không tìm thấy kết quả"
    end
    html = ""
    html << '<div >'
	languages = {"VI"=>"Tiếng Việt",
				  "EN"=>"Tiếng Anh",
				  "DE"=>"Tiếng Đức",
				  "FR"=>"Tiếng Pháp"}
    trans = get_translated_words(result)
    languages.each{|lang,lang_txt|
      next if trans[lang] == nil
	  
      html << '<p class="dict_key">'
      html <<  "<b>" << "Các từ tìm thấy trong :" + lang_txt << "</b>"
      html << '</p>'
      html << '<table class="table table-hover table-bordered ">'

	  html << '<tr>'
      ["Từ khóa","Từ dịch","Trong","Tự điển"].each{|label|
	    html << "<th>" + label + "</th>"
	  }
	  html << '</tr>'

      trans[lang].each{|x|
	  puts(x.inspect())
          dicts = ""
          n = 0
          x["dict"].each{|d|
             dicts << d << ","
             n = n + 1 
          }
          html << "<tr>"
		html << "<td>" + x["key"] + "</td>"
	    html << "<td>" + x["xlate"].sub(/>/,"]").sub(/</,"[").html_safe  + "</td>"
	    html << "<td>" + n.to_s + "</td>"
	    html << "<td>" + show_dicts(x["dict"]) + "</td>"
          html << "</tr>"
      }
      html << '</table>'
     }
    html << '</div>'
    return html
  end
  #####################################################################
end
