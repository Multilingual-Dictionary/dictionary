require 'whitesimilarity'
class DictResults 
	attr_accessor :error,:results
	def initialize(e=nil)
		@error=e;
		@results=Hash.new()
	end
	def resultOf(name)
	end
end
class DictService
	attr_accessor :res , :error , :search_mode, :search_key, :src_lang, :tgt_lang , :parser
	def lookup_init()
		@res = Hash.new
		@error= nil
	end
	def initialize()
		@search_key=nil
		@parser=nil
	end
	def set_search_key(key)
		@search_key=key
	end
	def set_search_mode(mode)
		@search_mode=mode
		puts ( "DICT SERVICE MODE "+ @search_mode)
	end
	def set_parser(name)
		@parser= DictResultParser.new(name)
	end
	def set_languages(src_lang,tgt_lang)
		@src_lang=src_lang.upcase
		@tgt_lang=tgt_lang.upcase
	end
	def sorted_result(r)
		return r if @search_key==nil
		scores=[]
		i = 0
		r[:entries].each{|e|
			scores<< [i,WhiteSimilarity.similarity(@search_key,e[:key])]
			i = i + 1
		}
		sorted = scores.sort{|p1,p2| p2[1]<=>p1[1]}
		sorted_entries = []
		sorted.each{|i|
			sorted_entries << r[:entries][i[0]]
		}
		r[:entries] = sorted_entries
		return r
	end
	def result(err=nil)
		ret = []
		if(err!=nil)
			@error = err
			return  ret
		end
		@res.each_value {|r|
			ret << sorted_result(r)
		}
		return ret
	end
	def add_entry( dict_name, key , text , infos=nil )
		return if text.empty?
		if @parser != nil
			res = @parser.parse(key,text,infos)
			if res != nil
				key = res["key"] if res.has_key?("key")
				text = res["text"] if res.has_key?("text")
				key = res["infos"] if res.has_key?("infos")
			end
		end
		if !@res.has_key?dict_name 
			@res [dict_name] = 
				{ :dict_name => dict_name ,
				  :entries   => [] }
		end
		txt=[]
		text.each{|t|
			txt << t.force_encoding(Encoding::UTF_8) if t != ""
		}
                k_e = key.dup
		k_e = k_e.force_encoding(Encoding::UTF_8),
		@res[dict_name][:entries] << 
			{ :key => k_e,
			  :text=> txt,
			  :infos => infos}
	end
end

class DictResultParser
	def initialize(name)
		if name != nil
			@name=name.strip.upcase
		else
			@name=""
		end
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
	def parse(key,text,infos)
		case @name
		when "HND"
			new_text = []
			text.each{|txt|
				next if txt[0] != "-"
				txt=txt.gsub("-","").strip
				new_text << remove_notes(txt,"{","}")
			}
			return {
				"key" => key.gsub('@','').strip,
				"text" => new_text
			}
		else
			return nil
		end
	end
end


