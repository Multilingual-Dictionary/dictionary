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
	attr_accessor :res , :error , :search_mode, :search_key, :src_lang, :tgt_lang
	def lookup_init()
		@res = Hash.new
		@error= nil
	end
	def initialize()
		@search_key=nil
	end
	def set_search_key(key)
		@search_key=key
	end
	def set_search_mode(mode)
		@search_mode=mode
		puts ( "DICT SERVICE MODE "+ @search_mode)
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
		if !@res.has_key?dict_name 
			@res [dict_name] = 
				{ :dict_name => dict_name ,
				  :entries   => [] }
		end
		txt=[]
		text.each{|t|
			txt << t.force_encoding(Encoding::UTF_8) if t != ""
		}
		@res[dict_name][:entries] << 
			{ :key => key.force_encoding(Encoding::UTF_8),
			  :text=> txt,
			  :infos => infos}
	end
end
