require "./lib/dict/rfc2229_dict_service"
class Dictionaries
	def initialize(dict_infos)
		@dict_infos=dict_infos;	
	end
	def dict_infos()
		return @dict_infos
	end
	def dict_infos_by_sys_name(name)
		@dict_infos.each { |inf|
			if inf.dict_sys_name.casecmp(name)==0
				return inf
			end
		}
		return nil
	end
	def lookup(to_search,dict_infos)
		case dict_infos.protocol.upcase
		when "RFC2229"
			return RFC2229DictService.new().lookup(to_search,dict_infos.dict_sys_name)
		else
			return []
		end
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
		return lookup_using_dicts(to_search,[dict])
	end
	def lookup_by_lang(to_search,src_lang,tgt_lang)
		dicts =  []
		@dict_infos.each { |inf|
			if (inf.lang.upcase==src_lang.upcase and
			    inf.xlate_lang.upcase==tgt_lang.upcase )
				dicts << inf.dict_sys_name 
			end
		}
		return lookup_using_dicts(to_search,dicts)
	end
end

