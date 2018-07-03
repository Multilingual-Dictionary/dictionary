require_relative 'dict_service'

class GlossaryDictService < DictService 
	def initialize(cfg=nil)
		@cfg = cfg
		##puts("INIT GLOSSARY SERVICE")
		##puts(@cfg.inspect())
	end
	def lookup(to_search,dict_id=nil)
		lookup_init()
		##puts("DICT ID "+ dict_id + " " + to_search)
		##puts("MODE "+ @search_mode)
		if(@search_mode=='search_contain')
		  query = sprintf(
			"select * from glossaries where dict_id= '%s' ",
			dict_id)
		  to_search.split(' ').each{|w|
 		     query << " and key_words like '%"
		     query << w << "%' "
		  }
		  ##puts(query)
                  results = Glossary.find_by_sql(query)
		else
                  results = Glossary.where(
                          [ "dict_id = :dict_id and key_words = :key_words ",
                                { dict_id: dict_id , key_words: to_search } ] )
                end
		results.each(){|r|
			attr = ''
			attr << "/" + r.word_type  if r.word_type != ""
			attr << "/" + r.category  if r.category != ""
			attr << "/" if attr != ""
			key = r.key_words  
			key << " " << attr if attr != ""
			infos=Hash.new
			infos[:key_words]=r.key_words
			infos[:key_attr]=attr
			infos[:primary_xlate]=r.primary_xlate
			infos[:secondary_xlate]=r.secondary_xlate
			add_entry(@cfg.dict_sys_name,key,[r.primary_xlate,r.secondary_xlate],infos)
		}
		return result()
	end
end 
