require "./lib/dict/rfc2229_dict_service"
require "./lib/dict/glossary_dict_service"
require "./lib/dict/wiktionary_dict_service"
class Dictionaries
  def initialize(dict_infos)
    @search_mode='search_exact'
    @search_key=nil
    @dict_infos=dict_infos;  
  end
  def dict_infos()
    return @dict_infos
  end

  def set_search_mode(mode='search_exact')
    @search_mode = mode
    puts("DICT SET " + @search_mode)
  end
  def set_search_key(key=nil)
    @search_key = key
    puts("DICT SET " + @search_key)
  end
  
  def dict_infos_by_sys_name(name)
    @dict_infos.each { |inf|
      if inf.dict_sys_name.casecmp(name)==0
        return inf
      end
    }
    return nil
  end
  def dict_name(sys_name)
    @dict_infos.each { |inf|
      puts ( inf.dict_sys_name + " NAME " + sys_name )
      if inf.dict_sys_name.casecmp(sys_name)==0
        return inf.dict_name
      end
    }
    puts ( " NOTFOUND " + sys_name )
    return sys_name
  end
  ###########    LOOKUP ###########################################
  def lookup(to_search,dict_infos)
    puts("LOOKUP INFOS "+ dict_infos.inspect())
    puts("LOOKUP USING DICT "+ dict_infos.dict_sys_name)
    puts("LOOKUP USING PROTOCOL"+ dict_infos.protocol.upcase )
    case dict_infos.protocol.upcase
    when "RFC2229"
      service= RFC2229DictService.new()
    when "GLOSSARY"
      service= GlossaryDictService.new(dict_infos)
    when "WIKTIONARY"
      service= WiktionaryDictService.new(dict_infos)
    else
      return []
    end
   service.set_search_mode(@search_mode)
   service.set_search_key(to_search)
   return service.lookup(to_search,dict_infos.dict_sys_name)
  end
  def lookup_using_dicts(to_search,dicts)
    ret = []
    dicts.each{|n|
      inf = dict_infos_by_sys_name(n)
      if inf != nil
        res = lookup(to_search,inf)
        if res != nil 
          res.each{|tmp|
            ret << tmp
          }
        end
      end
    }
    return ret
  end

  def lookup_using_dict(to_search,dict)
    puts("lookup_using_dict ")
    return lookup_using_dicts(to_search,[dict])
  end
  def lookup_by_lang(to_search,src_lang,tgt_lang)
    puts("lookup_by_lang ")
    dicts =  []
    @dict_infos.each { |inf|
      if (
	  ( inf.lang.upcase==src_lang.upcase or
	    "ALL"==src_lang.upcase ) and
          ( inf.xlate_lang.upcase==tgt_lang.upcase or
            "ALL"==tgt_lang.upcase ) )
        dicts << inf.dict_sys_name 
      end
    }
    return lookup_using_dicts(to_search,dicts)
  end
  ###########    END-LOOKUP ###########################################
  ###########    RENDER ###########################################
  def render_result(result)
    html = ""
    result[:entries].each{|entry|
      key =  entry[:key]
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
      html << '<div class="indented">'
      html << '<p class="dict_key">'
      html <<  "<b>" << key.html_safe  << "</b>"
      html <<  "<i>" << attr.html_safe << "</i>"  if attr != ""
      html << '<p>'
      html << '<ul>'
      entry[:text].each{|t|
        html << '<li><p class=dict_text>'
	html << t.html_safe 
	html << '</p></li>'
      }
      html << '</ul>'
      html << '</div>'
    }
    return html
  end
  ###########    END-RENDER ###########################################
end
