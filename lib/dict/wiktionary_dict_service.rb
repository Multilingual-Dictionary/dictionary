require_relative 'dict_service'
require_relative 'wiktionary'

class WiktionaryDictService < DictService 
	def initialize(cfg=nil)
		@cfg = cfg
		@wiktionary = Wiktionary.new(@cfg.url)
	end
	def lookup(to_search,dict_id=nil)
		lookup_init()
                wik_res = @wiktionary.query(to_search,@cfg.xlate_lang)
		add_entry(@cfg.dict_sys_name,to_search,wik_res)
		return result()
	end
end 

class CFG
    attr_accessor :url,:dict_sys_name,:xlate_lang
	def initialize(name,url,lang)
		@dict_sys_name = name
		@xlate_lang = lang
		@url  = url
	end
end

#TEST#cfg = CFG.new("WIKI","en.wiktionary.org","DE")
#TEST#s = WiktionaryDictService.new(cfg)
#TEST#r = s.lookup("love")
#TEST#puts(r.inspect())
