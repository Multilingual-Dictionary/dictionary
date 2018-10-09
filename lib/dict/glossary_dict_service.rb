require_relative 'dict_service'
require_relative 'glossary'
require 'json'
require "unicode_utils/casefold"

class GlossaryDictService < DictService 

	def initialize(cfg=nil)
		@glossary=GlossaryLib.new(cfg)
  	end

	##
	##  LOOKUP ( to_search .. )
	##

	def lookup(to_search,dict_id="")

		lookup_init()
    

		indices = @glossary.search_indices(to_search,dict_id,@src_lang,@search_mode)

		item_ids = ""
		indices.each{|item_id,r|
			item_ids << "," if  item_ids != ""
			item_ids << "'" << item_id << "'"
		}
    		### nothing found!
		return result() if item_ids == ""


		### For the item_ids search for all translated-keywords related

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

		printf("XLATED %s\n",xlated.inspect())


		### For the item_ids search for all dictionary-entries related
		
		results = @glossary.client.query(sprintf(
			"select * from glossaries where item_id in (%s) ",item_ids))
		results.each(){|r|	 ### each dictionary-entry
			##printf("RESULT %s\n",r.inspect())
			xlated_word= Hash.new
			txt = []
			html_txt = []
			attr = ""
			##
			## parse json-data
			##
			begin
				entry_data=JSON.parse(r['data'])
			rescue
				entry_data=Hash.new ## empty ! just in case!
			end
			##printf("ENTRY %s\n",entry_data.inspect())
			## key-words of this entry 
			key_words = indices[r['item_id']]['key_words']
			key_lang = indices[r['item_id']]['lang']
			printf("KEY %s,%s\n",key_words,key_lang)
			##
			## get xlated and another informations from entry_data
			##
			entry_data.each{|tag,value|
				##printf("TAG %s,VALUE %s\n",tag,value)
				pos = tag.index(":")
				if pos == nil
					tag_key=tag
					tag_lang=""
				else
					tag_key=tag[0,pos]
					tag_lang=tag[pos+1,2]
				end
				##printf("TAG [%s][%s]\n",tag_key,tag_lang)
				case tag_key
				when "#TERM"
					##printf("is term\n")
					txt << "["+tag_lang+"] "+ value if value!=""
				when "#CATEGORY"
					attr << "/" + value if value!=""
				when "#GRAMMAR"
					attr << "/" + value if value!=""
				when "#HTML"
					html_txt << "<html>"+ value + "</html>" if value!=""
				else
					txt << "["+tag_lang+"] "+ value if value!=""
				end
			}
			attr << "/" if attr != ""
			key = key_words	
			key << " " << attr if attr != ""
			infos=Hash.new
			infos[:key_words]=key_words
			infos[:key_lang]=key_lang
			infos[:xlated_word]=xlated[r['item_id']]
			if html_txt.size!=0
				add_entry(r['dict_id'],key,html_txt,infos)
			else
				add_entry(r['dict_id'],key,txt,infos)
			end
		}
		return result()
		end
end 
