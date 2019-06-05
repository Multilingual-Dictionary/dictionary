require_relative 'dict_service'
require_relative 'glossary'
require 'json'
require "unicode_utils/casefold"

class GlossaryDictService < DictService 

	def initialize(cfg=nil,dict_cfgs=nil)
		@glossary=GlossaryLib.new(cfg)
		@entries=Hash.new
		@dict_configs=dict_cfgs
		@primary_lang=Hash.new
		@multi_ling=Hash.new
		@to_search=Hash.new
		
  	end

	def debug(s)
		File.write("./debug.txt",s,mode:"a")
	end

	##
	##  get primary language of the dictionary
	##  [ from dict_configs ]
	##

	def primary_lang(dict_id)
		l = @primary_lang[dict_id]
		return l if l!=nil
		l = ""
		cfg = @dict_configs[dict_id]
		if cfg == nil or cfg["ext_cfg"] == nil or cfg["ext_cfg"]["languages"]==nil
			@primary_lang[dict_id]=""
			return ""
		end
		l = cfg["ext_cfg"]["languages"]["PRIMARY_LANGUAGE"]
		l = "" if l == nil
		@primary_lang[dict_id]=l
		return l
	end


	##
	##  is this dict multi_lingual
	##  [ from dict_configs ]
	##

	def is_multilingual (dict_id)
		it_is = @multi_ling[dict_id]
		return it_is if it_is!=nil
		it_is = false
		cfg = @dict_configs[dict_id]
		if cfg == nil 
			@multi_ling[dict_id]=it_is
			return it_is
		end
		supported=Hash.new
		["src_languages","tgt_languages"].each{|st|
			next if cfg[st]==nil
			cfg[st].each{|l|
				supported[l]=l
			}
		}
		if supported.size>2
			it_is = true
		end
		@multi_ling[dict_id]=it_is
		return it_is
	end

	##
	##  add entry -> buffer
	##

	def add_entry_to_buffer(key_words,key_lang,xlated,entry)
		dict_id=entry['dict_id']
		##debug(sprintf("add_entry id(%s),lang(%s),[%s]\n",dict_id,key_lang,key_words))
		##
		## parse json-data
		##
		begin
			entry_data=JSON.parse(entry['data'])
		rescue
			##printf("Data Error![%s]\n",entry['data'])
			return 
		end
		##debug(sprintf("ENTRYDATA [%s]\n",entry_data.inspect()))
		grammar=entry_data["#GRAMMAR"]
		grammar="" if grammar==nil
		category=entry_data["#CATEGORY"]
		category="" if category==nil
		entry_num=entry_data["#ENTRY_NUM"]
		entry_num="" if entry_num==nil
		hash_key=  dict_id + key_words + key_lang + grammar
		@entries[hash_key]=Hash.new if @entries[hash_key]==nil
		@entries[hash_key][entry_num]=
				{"dict_id"=>dict_id,
				"key_words"=>key_words,
				"grammar"=>grammar,
				"category"=>category,
				"key_lang"=>key_lang,
				"xlated_word"=>xlated,
				"entry_data"=>entry_data}
	end

	##
	##  Build html text ( for display )
	##

	def build_text(dict_id,entry_data,key_lang,num)

		if entry_data["#HTML"]!=nil
			### this guy already has HTML text .. dont need to build
			return entry_data["#HTML"]
		end
		multi_lingual= is_multilingual(dict_id)
		primary_lang=primary_lang(dict_id)

		i = 1
		html_txt = ""

		####### For tag TERM:LANG
		txt=""
		entry_data.each{|tag,value|
			next if tag[0,5]!="#TERM"
			next if tag[6,2]==primary_lang  ## dont show key if it is in source language
			txt << "[" + tag[6,2] + "] " if multi_lingual
			txt << value 
			txt << "<br/>"
		}
		html_txt << '<p class="dict_text">'
		if num != "0" 
			html_txt << sprintf("<b>%s. </b>",num)
		end
		html_txt << txt
		html_txt << '</p>'
		####### For tag EXPLAIN:LANG
		txt=""
		entry_data.each{|tag,value|
			next if tag[0,8]!="#EXPLAIN"
			txt << "[" + tag[9,2] + "] " if multi_lingual
			txt << value 
		}
		if txt != ""
			html_txt << '<p class="dict_text">'
			html_txt << txt
			html_txt << '</p>'
		end
		####### For tag EXAMPLES:LANG
		txt = ""
		entry_data.each{|tag,value|
			next if tag[0,9]!="#EXAMPLES"
			txt << "[" + tag[10,2] + "] " if multi_lingual
			txt << value 
		}
		if txt != ""
			html_txt << '<p class="dict_text" ><i>'
			html_txt << txt
			html_txt << '</i></p>'
		end
		html_txt << "</i></p>"
		return html_txt
	end	
	##
	##  Build html text ( for case TMX data )
	##
	def build_tmx_text(dict_id,entry_data,key_lang,num)
		html_txt = ""
		html_txt << '<p class="dict_text">'
		if num != "0" 
			html_txt << sprintf("<b>%s. </b>",num)
		end
		entry_data.each{|tag,value|
			next if tag[0,7]!="#PHRASE"
			if tag[8,2]==key_lang 
				html_txt << value 
			end
		}
		html_txt << '</p>'
		html_txt << '<p class="dict_text">'
		html_txt << '<i>'
		entry_data.each{|tag,value|
			next if tag[0,7]!="#PHRASE"
			if tag[8,2]!=key_lang 
				html_txt << value 
			end
		}
		html_txt << '</i>'
		html_txt << '</p>'
		return html_txt
	end	
		
	##
	##  add entry->base-class ( for building the final result )
	##
	def do_add_entry(entry,html_txt,infos)
		debug(sprintf("ADD DICT ENTRY(%s)\nINF(%s)\n",entry.inspect(),infos.inspect()))

		
		key_words= entry['key_words']
		infos[:key_words]=key_words
		infos[:key_lang]=entry['key_lang']


		attr = ""
		["grammar","category"].each{|tag|
			attr << "/" << entry[tag] if entry[tag] != ""
		}
		attr << "/" if attr != ""
		primary_lang=primary_lang(entry['dict_id'])
		key_term=""
		if primary_lang != "" and infos[:xlated_word] != nil and infos[:xlated_word][primary_lang]!=nil
			infos[:xlated_word][primary_lang].each{|w|
				key_term << "," if key_term !=  ""
				key_term << w 
			}
		end

		infos[:key_attr]=attr
		infos[:attributes]=attr
		key_txt = '<p class="dict_key_1">'
		key_txt << "<b>"
		if key_term==""
			if key_words.index("$phrase$")!= nil
				key_txt << @to_search
			else
				key_txt << key_words
			end
		else
			key_txt << key_term
		end
		key_txt << "</b>"
		if attr != ""
			key_txt << ' <i>' + attr + '</i>' 
		end
		key_txt << '</p>'

		infos[:dict_entry_key]= key_txt
		add_entry(entry['dict_id'],
			  key_words,
			  [html_txt],
			  infos)
		##debug(sprintf("INFOS-FINAL\n %s\n",infos.inspect()))
	end
	##
	##  flush entries in buffer
	##
	def flush_buffer()
		@entries.each{|h,e|
			infos=Hash.new
			infos[:xlated_word]=Hash.new
			html_txt=""
			if e.size > 1
				i = 1 
			else
				i = 0 
			end
			sorted=e.sort.to_h
			first_entry=sorted.first[1]
			examples=[]
			if first_entry["key_words"].index("$phrase$") != nil
				## Special case TMX 
				sorted.each{|entry_num,entry|
					html_txt << build_tmx_text(entry['dict_id'],entry['entry_data'],entry["key_lang"],i.to_s)
					i = i + 1 
					ex = Hash.new
					entry['entry_data'].each{|tag,value|
						next if tag[0,7]!="#PHRASE"
						ex[tag[8,2]]=value
					}
					examples << ex
				}
			else
				## normal case : regular dictionary entry
				sorted.each{|entry_num,entry|
					## collects all xlated and build html text
					entry['xlated_word'].each{|lang,words|
						infos[:xlated_word][lang]=Hash.new if infos[:xlated_word][lang]==nil
						words.each{|w|
							infos[:xlated_word][lang][w]=w
						}
					}
					html_txt << build_text(entry['dict_id'],entry['entry_data'],entry["key_lang"],i.to_s)
					i = i + 1 
				}
				infos[:xlated_word].each{|lang,x|
					### eliminate duplicated keys!
					infos[:xlated_word][lang]= x.keys
				}
			end
			infos[:examples]=examples
			do_add_entry(first_entry,
				     "<html>"+html_txt+"</html>",
				     infos)
		}
	end

	##
	##  LOOKUP ( to_search .. )
	##

	def lookup(to_search,dict_id="")

		@to_search=to_search
		lookup_init()
		@entries=Hash.new  
		
		### select glossaries
		glossary_ids=[]
		tmx_ids=[]
    		dict_id.split(",").each{|id|
			cfg = @dict_configs[id]
			if cfg!=nil and cfg["type"]=="tmx"
				tmx_ids << id
			else
				glossary_ids << id
			end
    		}
		@glossary.select_glossaries(glossary_ids,tmx_ids)

		## search! this returns indices matched
		indices = @glossary.search_indices(to_search,dict_id,@src_lang,@search_mode)

		item_ids = ""
		indices.each{|item_id,r|
			item_ids << "," if  item_ids != ""
			item_ids << "'" << item_id << "'"
		}
    		## nothing found!
		return result() if item_ids == ""


		###
		### For the item_ids search for all translated-keywords related
		###

		results = @glossary.client.query(sprintf(
			"select * from glossary_indices where item_id in (%s) ",item_ids))
		xlated = Hash.new
		results.each(){|r|
			if not xlated.has_key?(r['item_id'])
				 xlated[r['item_id']]=Hash.new
			end
			if not xlated[r['item_id']].has_key?(r['lang'])
				 xlated[r['item_id']][r['lang']]=[]
			end
			next if r['original_key_words'].index("$phrase$") != nil  ## ignore! not a real! 

			xlated[r['item_id']][r['lang']]<<r['original_key_words']
		}
		### now we have all translated-keywords in xlated!


		###
		### For the item_ids search for all dictionary-entries related
		###
		
		results = @glossary.client.query(sprintf(
			"select * from glossaries where item_id in (%s) ",item_ids))

		results.each(){|r|	 ### each dictionary-entry
			## add -> buffer for post processing
			add_entry_to_buffer(
				indices[r['item_id']]['key_words'],
				indices[r['item_id']]['lang'],
				xlated[r['item_id']],
				r)
		}
		flush_buffer()	## flush buffer ( this build results! )
		return result()
	end
end 
