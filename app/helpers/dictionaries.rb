class Dictionaries
	def initialize(dict_infos)
		@dict_infos=dict_infos;	
	end
	def dict_infos()
		return @dict_infos
	end
	def lookup_using_dicts(to_search,dicts)
		ret = "search " + to_search + " in "
		dicts.each{|d|
			ret << " "
			ret << d
		}
		return ret
	end
	def lookup_using_dict(to_search,dict)
		return "USING DICT" + lookup_using_dicts(to_search,[dict])
	end
	def lookup_by_lang(to_search,src_lang,tgt_lang)
		dicts =  []
		@dict_infos.each { |inf|
			if (inf.lang.upcase==src_lang.upcase and
			    inf.xlate_lang.upcase==tgt_lang.upcase )
				dicts << inf.dict_sys_name 
			end
		}
		return "BY LANG" + lookup_using_dicts(to_search,dicts)
	end
end
