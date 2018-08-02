require_relative 'dict_service'
require_relative 'wiktionary'

class WiktionaryDictService < DictService 
	def initialize(cfg=nil)
		@cfg = cfg
		@wiktionary = Wiktionary.new(@cfg["url"])
	end
	def lookup(to_search,dict_id=nil)
		lookup_init()
		if @tgt_lang=="ALL"
			lang="DE,VI,FR"
                else
			lang=@tgt_lang
                end
                wik_res = @wiktionary.query(to_search,lang)

      		infos=Hash.new
      		infos[:key_words]=to_search
      		infos[:key_lang]="EN"
      		infos[:xlated_word]=wik_res
      		txt = []
		cnt=0
		wik_res.each{|l,words|
                   l = ""
                   words.each{|w|
			l << "," if l != ""
			l << w 
                   }
		   txt << l
		   cnt += 1
                }
		add_entry(@cfg["dict_sys_name"],to_search,txt,infos) if cnt > 0
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

#cfg = {"dict_sys_name"=>"WIKI",
#       "url" => "en.wiktionary.org"}
#s = WiktionaryDictService.new(cfg)
#s.set_languages("EN","DE,FR")
#r = s.lookup("love")
#puts(r.inspect())
