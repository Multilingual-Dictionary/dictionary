require "./lib/dict/rfc2229_dict_service"
require "./lib/dict/glossary_dict_service"
require "./lib/dict/wiktionary_dict_service"
require "./lib/dict/google_dict_service"
require 'whitesimilarity'

class Dictionaries
  attr_accessor :lang_codes,:src_lang_supported,:tgt_lang_supported,:dict_infos
  
  def initialize(dict_infos)
    @search_mode='search_exact'
    @search_key=nil
    @src_lang_supported=Hash.new
    @tgt_lang_supported=Hash.new
	@lang_codes = 
		{"VI"=>"Tiếng Việt",
		 "EN"=>"Tiếng Anh",
		 "DE"=>"Tiếng Đức",
	     "FR"=>"Tiếng Pháp"}
    @dict_infos=Hash.new
   
    dict_num=0
    dict_infos.each{|inf|
      dict_num += 1
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
          "dict_num" => dict_num,
          "dict_sys_name" => inf.dict_sys_name,
          "dict_name" => inf.dict_name,
          "protocol" => inf.protocol,
          "url" => inf.url,
          "ext_cfg" => ext_cfg,
          "src_languages" => to_set_of(inf.lang),
          "tgt_languages" => to_set_of(inf.xlate_lang)
        }
    }
    @dict_infos.each{|n,inf|
       inf["src_languages"].each{|l|
          @src_lang_supported[l]= lang_code_name(l)
       }
       inf["tgt_languages"].each{|l|
	      @tgt_lang_supported[l]=lang_code_name(l)
       }
    }
	
  end
  def lang_code_name(l)
    return @lang_codes[l] if @lang_codes[l] != nil
	return l
  end
  def to_set_of(txt)
    s = []
    txt.upcase.split(",").each{|l|
      s << l.strip.upcase
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
  def dict_num(sys_name)
    inf =  @dict_infos[sys_name.upcase]
    return inf["dict_num"] if inf != nil
    return 0
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

  def process_xlate(entry,dict_infos)
    if entry[:infos][:xlated_word] != nil
      ##printf("Already have xlate\n")
      return 
    end
    ## need processing
    if dict_infos["src_languages"].length==1 and
       dict_infos["tgt_languages"].length==1 and 
       dict_infos["src_languages"][0]==dict_infos["tgt_languages"][0] 
        return
    end
    xlate_lang=dict_infos["tgt_languages"][0]
	entry[:infos][:xlated_word]=Hash.new
	entry[:infos][:xlated_word][xlate_lang]=[]
    txts = entry[:text]
    if txts != nil
      txts.each{|txt|
	   txt=remove_notes(txt,"(",")")
	   txt=remove_notes(txt,"{","}")
           txt=remove_notes(txt,"[","]")
	   txt=remove_notes(txt,"<",">")
	   ##printf("TXT_RM(%s)\n",txt)
           tokenize(txt).each{|tk|
             tk = tk.strip
             next if tk == ""
             entry[:infos][:xlated_word][xlate_lang]<<tk
           }
      }
    end

  end
  ##
  ## process result -> infos Hash
  ## 
  def process_result(result)
	return result if result.length==0
	processed=[]
	result.each{|r|
          dict_info=@dict_infos[r[:dict_name].to_s.upcase]
	  r[:entries].each{|e|
            if e[:infos] == nil
		e[:infos] = Hash.new
	    end
  	    process_key(e)
  	    process_xlate(e,dict_info)
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
  def lookup(to_search,dict_infos,src_lang,tgt_lang,dict_name=nil)
   begin
    case dict_infos["protocol"].upcase
    when "RFC2229"
      service= RFC2229DictService.new()
    when "WIKTIONARY"
      service= WiktionaryDictService.new(dict_infos)
    when "GOOGLE"
      service= GoogleDictService.new(dict_infos)
    else
      puts("NOT SUPPORTED")
      return nil
    end
	rescue
	  return nil
   end
   service.set_search_mode(@search_mode)
   service.set_search_key(to_search)
   service.set_languages(src_lang,tgt_lang)
   service.set_parser(dict_infos["ext_cfg"]["result_parser"])
   if dict_name==nil
      dict_name= dict_infos["dict_sys_name"]
   end
   return service.lookup(to_search,dict_name)
  end
  def lookup_glossary(to_search,dict_infos,src_lang,tgt_lang,dict_name=nil)
      service= GlossaryDictService.new(dict_infos)
      service.set_search_mode(@search_mode)
      service.set_search_key(to_search)
      service.set_languages(src_lang,tgt_lang)
      return service.lookup(to_search,dict_name)
  end


  ##
  ##  use google-translator to detect language
  ##
  def detect_lang(to_search,lang)
    @dict_infos.each { |k,inf|
      if inf["protocol"].upcase==="GOOGLE"
        service= GoogleDictService.new(inf)
        return service.detect_language(to_search)
      end
    }
    return lang  ## we dont have google!
  end
  ##
  ##  lookup using many dictionaries
  ##
  def lookup_dictionaries( to_search,source_lang,target_lang,reference_lang,dictionaries)
    #printf("TOSEARCH %s\n",to_search)
    #printf("SRC_LANG %s\n",source_lang)
    #printf("TGT_LANG %s\n",target_lang)
    #printf("REF_LANG %s\n",reference_lang)
    #printf("SELECT DICT %s\n",dictionaries)

    ret = []
    if source_lang=='ALL'
      src_lang=detect_lang(to_search,source_lang)
    else
      src_lang=source_lang
    end
    tgt_lang=""
    if reference_lang=="ALL"
      @tgt_lang_supported.each{|l,n|
	      tgt_lang << "," if tgt_lang != ""
		  tgt_lang << l
      }
    else
      tgt_lang = target_lang
      langs = {target_lang=>target_lang} 
      reference_lang.split(",").each{|l|
        next if langs.has_key?(l)
        tgt_lang << "," << l
	langs[l] = l
      }
     end
     #printf("TGTLANG %s\n",tgt_lang)
     glossary_names=""
     glossary_infos=Hash.new
     dictionaries.split(',').each{|n|
       inf = dict_infos_by_sys_name(n)
       if inf != nil
         if inf["protocol"].upcase=="GLOSSARY"
           glossary_names << "," if glossary_names !=""
           glossary_names << n
		   glossary_infos[n.upcase] =  inf
         else
           res = lookup(to_search,inf,src_lang,tgt_lang)
           if res != nil 
             res.each{|tmp|
               ret << tmp
             }
           end
        end
      end
     }
     if glossary_names!=""
       printf("GLOSSARY! (%s)\n",glossary_names)
       res = lookup_glossary(to_search,glossary_infos,src_lang,tgt_lang,glossary_names)
       if res != nil 
         res.each{|tmp|
           ret << tmp
         }
	   end
     end
     return process_result(ret)
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
    translated=Hash.new
    return translated if result==nil
    result.each(){|r|
      r[:entries].each{|entry|
        next if entry[:infos] == nil
        next if entry[:infos][:xlated_word]==nil
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
    tmp= sorted_translated(translated)
	
	return tmp
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
	  attr= "" if attr==nil
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
    trans = get_translated_words(result)

    @lang_codes.each{|lang,lang_txt|
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
