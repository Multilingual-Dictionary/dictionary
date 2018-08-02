require 'rubygems'
require 'nokogiri'
require 'open-uri'

class Wiktionary

  def initialize (url="en.wiktionary.org")
    @uri = "https://" + url +
  	"/w/api.php?format=xml&action=query&rvprop=content&prop=revisions&redirects=1"
    @lang_map = { "ENG" => "English",
	          "DE"  => "German" ,
	          "FR"  => "French" ,
	          "VI"  => "Vietnamese" }
  end

  def parse_entries(e,results)
	e.split("{{").each{|item|
		idx= item.index("}}")
		item = item[0,idx] if idx != nil
		i = 0;
		lang=""
		trans=""
		splitted= item.split("|").each(){|s|
			case i
			when 1
			  lang = s
			when 2
			  trans = s
			else
			end
			i  = i + 1
		}
		if(lang !=  "" and trans != "" and trans != "null")
                        trans.gsub!(/[\[\]{}\(\)]/,"")
			results[trans]=trans if trans != ""
		end
	}
	return results
  end
  def wiki_parse(txt,languages)

    in_trans = 0
    tmp=Hash.new
    languages.split(",").each{|l|
      l.strip!
      next if l==""
      tmp[l]=Hash.new
    }
    txt.split("\n").each{|l|
      l = l.strip
      if(l.index("=Translations=")!=nil)
        in_trans = 1
      else
        if(l.index("====")==0)
          in_trans = 0
        else
          if in_trans == 1
            tmp.each{|lang,a|
              idx=  l.index(@lang_map[lang])
              if idx !=nil and idx == 2
                   parse_entries(l,tmp[lang])
	      end
            }
          end
        end
      end
    }
    results=Hash.new
    tmp.each{|l,r|
       results[l]=[]
       r.each{|k,v|
          results[l] << v
       }
    }
    return results
  end
  def query(q,lang)
    uri = @uri + "&titles="+URI.escape(q)
    doc = Nokogiri::HTML(open(uri))
    return wiki_parse(doc.content,lang)
  end
end

##w =  Wiktionary.new
##puts(w.query(ARGV[0],"DE,FR,VI").inspect())


