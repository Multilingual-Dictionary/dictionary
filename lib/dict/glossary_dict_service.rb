require_relative 'dict_service'
require_relative 'glossary'
require 'json'
require "unicode_utils/casefold"

class GlossaryDictService < DictService 

	def initialize(cfg=nil)
		@glossary=GlossaryLib.new(cfg)
		@entries=Hash.new
  	end

	def debug(s)
		##File.write("./debug.txt",s,mode:"a")
	end

	##
	##  add entry -> buffer
	##

	def add_entry_to_buffer(key_words,key_lang,xlated,entry)
		dict_id=entry['dict_id']
		## debug(sprintf("add_entry id(%s),lang(%s),[%s]\n",dict_id,key_lang,key_words))
		##
		## parse json-data
		##
		begin
			entry_data=JSON.parse(entry['data'])
		rescue
			##printf("Data Error![%s]\n",entry['data'])
			return 
		end
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
	##  flush entries in buffer
	##
	def do_add_entry(dict_id,key_words,html_txt,infos)
		##debug(sprintf("ADD DICT(%s)KEYW(%s)TXT(%s)INF(%s)\n",dict_id,key_words,html_txt,infos))
		debug(sprintf("ADD DICT(%s)KEYW(%s)\nTXT(%s)\n",dict_id,key_words,html_txt))
		add_entry(dict_id,key_words,[html_txt],infos)
	end
	##
	##  Build html text ( for display )
	##
	def build_text(entry_data,key_lang,num)

		if entry_data["#HTML"]!=nil
			### this guy already has HTML text .. dont need to build
			return entry_data["#HTML"]
		end

		i = 1
		html_txt = ""

		####### For tag TERM:LANG
		txt=""
		entry_data.each{|tag,value|
			next if tag[0,5]!="#TERM"
			next if tag[6,2]==key_lang  ## dont show key if it is in source language
			txt << value 
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
			next if tag[9,2]==key_lang  ## dont show key if it is in source language
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
			next if tag[10,2]==key_lang  ## dont show key if it is in source language
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
	##  flush entries in buffer
	##
	def flush_buffer()
		@entries.each{|h,e|
			infos=Hash.new
			infos[:xlated_word]=Hash.new
			dict_id=""
			key_words=""
			grammar=""
			category=""
			html_txt=""
			if e.size > 1
				i = 1 
			else
				i = 0 
			end
			e.sort.to_h.each{|entry_num,entry|
				dict_id=entry['dict_id'] if dict_id==""
				key_words=entry['key_words'] if key_words==""
				grammar=entry['grammar'] if grammar==""
				category=entry['category'] if grammar==""
				infos[:key_words]=entry['key_words']
				infos[:key_lang]=entry['key_lang']
				entry['xlated_word'].each{|lang,words|
					infos[:xlated_word][lang]=Hash.new if infos[:xlated_word][lang]==nil
					words.each{|w|
						infos[:xlated_word][lang][w]=w
					}
				}
				debug(sprintf("entrydata %s\n",entry['entry_data'].inspect()))
				html_txt << build_text(entry['entry_data'],entry["key_lang"],i.to_s)
				i = i + 1 
			}
			infos[:xlated_word].each{|lang,x|
				infos[:xlated_word][lang]= x.keys
			}
			attr = ""
			attr << "/" << grammar if grammar != ""
			attr << "/" << category if category != ""
			key_words << " " << attr + "/" if attr != ""
			do_add_entry(dict_id,key_words,"<html>"+html_txt+"</html>",infos)
		}
		debug(sprintf("ENDFLUSH\n"))
	end

	##
	##  LOOKUP ( to_search .. )
	##

	def lookup(to_search,dict_id="")

		lookup_init()
		@entries=Hash.new  
    
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
