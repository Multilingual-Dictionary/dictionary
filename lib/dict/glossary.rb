#########################################################################################
##	GLOSSARY LIB 
#########################################################################################

require "unicode_utils/casefold"
require 'whitesimilarity'

class GlossaryLib
	attr_accessor :client

	def debug(s)
		##File.write("./debug.txt",s,mode:"a")
	end

	#########################################################################################
	##	INIT
	#########################################################################################

	def initialize(cfg=nil)
		if cfg!=nil
			@client = Mysql2::Client.new(
		    		:host => cfg["host"],
		    		:username => cfg["username"], 
		    		:password => cfg["password"] , 
		    		:database => cfg["database"])
		else
			@client=nil
		end
	end

	#########################################################################################
	##	UTILS
	#########################################################################################

	##
	##  Normalize key ( casefold and remove no alfa-num )
	##

	def normalize(key)
		return UnicodeUtils.casefold(key).gsub(/\p{^Alnum}/,"")
	end

	##
	##  split key->token ( for indexing) 
	##    [ split words => [word,word,...]
	##

	def split_key(key,max_key_size=50)
		splitted=Hash.new
		tmp=UnicodeUtils.casefold(key)
		tmp.gsub(/['\-\"]/," ").split(/\p{^Alnum}/).each{|k|
			k.strip!
			if k.size>max_key_size
				return []
			end
			splitted[k] = k.size if k != ""
		}
		### sort
		return splitted.sort_by{|k,s|-s}
	end

	def join_splitted(splitted)
		words = ""
		splitted.each{|w,s|
			words << w
		}
		return words
	end

	##
	##  calculate the hash of dictionary-entry
	##

	def hash_dict_entry(dict_id,data)
		md5 = Digest::MD5.new
		md5 << dict_id.upcase
		data.each{|k,v|
			v = "" if  v==nil
			v.strip!
			md5 << v.upcase
		}
		return md5.hexdigest
	end

	##
	## init ignored words
	##

	def init_ignored_words()
		return if @ignored != nil
	    @ignored=Hash.new
       [  "die","der","und","in","zu","den","das","nicht","von","sie",
		  "ist","des","sich","mit","dem","dass","er","es","ein","ich",
	      "auf","so","eine","auch","als","an","nach","wie","im","für",
		  "man","aber","aus","durch","wenn","nur","war","noch","werden",
		  "bei","hat","wir","was","wird","sein","einen","welche","sind",
		  "oder","zur","um","haben","einer","mir","über","ihm","diese",
		  "einem","ihr","uns","da","zum","kann","doch","vor","dieser",
		  "mich","ihn","du","hatte","seine","mehr","am","denn","nun",	
		  "unter","sehr","selbst","schon","hier","bis","habe","ihre","dann",	
		  "ihnen","seiner","alle","wieder","meine","gegen","vom","ganz",	
		  "einzelnen","wo","muss","ohne","eines","können","sei","ja",
		  "wurde","jetzt","immer","seinen","wohl","dieses","ihren","würde",
		  "diesen","sondern","weil","welcher","nichts","diesem","alles",
		  "waren","will","viel","mein","also","soll","worden","lassen",	
		  "dies","machen","ihrer","weiter","Leben","recht","etwas","keine",	
		  "seinem","ob","dir","allen","großen","Weise","müssen","welches",	
		  "wäre","erst","einmal","Mann","hätte","zwei","dich","allein","während",	
		  "anders","kein","damit","gar","euch","sollte","konnte","ersten",
		  "deren","zwischen","wollen","denen","dessen","sagen","bin","gut",
		  "darauf","wurden","weiß","gewesen",	"Seite","bald","weit","große",
		  "solche","hatten","eben","andern",	"beiden","macht","sehen",
		  "ganze","anderen","lange","wer","ihrem",
		  "zwar","gemacht","dort","kommen","heute","werde","derselben",
		  "ganzen","lässt","vielleicht","meiner"].each{|w|
			@ignored[w.downcase]=1
		}
	end
	def ignore_key(w)
		init_ignored_words() if @ignored == nil
		return true if @ignored[w.downcase]!=nil
		return true if w.index(/[0-9]/) != nil
		return false
	end
	#########################################################################################
	#	SELECT GLOSSARIES
	#########################################################################################
	def select_glossaries(glossary_ids,tmx_ids)
		@glossary_ids = glossary_ids
		@tmx_ids = tmx_ids
	end
	def dict_id_set ( dict_ids)
		dict_set="''"
		dict_ids.each{|dict_id|
			dict_id.each{|id|
      				dict_set << ",'"+@client.escape(id)+"'"
			}
		}
		return dict_set
	end
	#########################################################################################
	#	SEARCH INDICES
	#########################################################################################

	def search_indices(key,dict_id,lang,search_mode)
		splitted=split_key(key)
		normalized=normalize(key)
		if splitted.size==0
			return Hash.new ## empty
		end
		if search_mode != 'search_contain'
			#### SEARCH-EXACT
			indices= search_exact(normalized,[@glossary_ids],lang)
		else
			###  SEARCH - CONTAIN
			indices= search_contains( splitted, [@glossary_ids], lang)
		end
		###  SEARCH TMX
		if @tmx_ids.size==0
			return indices
		end
		search_keys=Hash.new
		##debug(sprintf("SPLITTED %s\n",splitted.inspect()))
		splitted.each{|k,s|
			next if ignore_key(k)
			search_keys[k]=s
		}
		##debug(sprintf("SEARCH %s\n",search_keys.inspect()))
		if search_keys.size>0
			tmx_indices = search_contains(search_keys, [@tmx_ids], lang)
			##debug(sprintf("TMX-RES %s\n",tmx_indices.inspect()))
			tmx_indices.each{|item_id,v|
				idx= v["key_words"].index("$phrase$")
				if idx != nil
					v["key_words"]=v["key_words"][idx,v["key_words"].length]
				end
				##debug(sprintf("%d,KEY %s\n",idx+8,v["key_words"]))
				keys_found=split_key(v["key_words"])
				##debug(sprintf("KEYFOUND %s\n",keys_found.inspect()))
				if key_is_valid(search_keys,keys_found)
					indices[item_id]=v
					##debug(sprintf("KEY %s OK\n",keys_found.inspect()))
				else
					##debug(sprintf("KEY %s INVALID\n",keys_found.inspect()))
				end
			}
		end
		return indices
	end
	def search_exact(normalized_keywords,dict_ids,lang)
		indices = Hash.new
		cond = sprintf("1 and dict_id in(%s)",dict_id_set(dict_ids))
		##debug(sprintf("COND %s\n",cond))
		query= sprintf("select original_key_words,item_id from glossary_indices where %s ",cond)
		query <<  " and " + sprintf( "lang = '%s' ",lang)
                query <<  " and " + sprintf( "key_words = '%s' ",@client.escape(normalized_keywords))
		##debug(sprintf("QUERY %s\n",query))
		res =  @client.query(query)
               	res.each{|r|
                       	indices[r['item_id']]={
				"lang" => lang,
				"key_words"=>r['original_key_words']
			}
               	}
		return indices
	end
	def search_contains(splitted,dict_ids,lang)
		indices = Hash.new
		query = ""
		splitted.each{|k,s|
			q = sprintf("select item_id from %s where lang='%s' and key_word like '%s' \n",
				'glossary_indices',
				lang,
				@client.escape(k)+"%")
			if query==""
				query = q 
			else
				query = q + " and item_id in (" + query +")" + "\n"
			end
		}
		res =  @client.query(sprintf(
				"select item_id from glossary_indices where item_id in(%s) and dict_id in(%s) order by key_len limit 50",
				query ,
				dict_id_set(dict_ids)))
		items = ""
               	res.each{|r|
			items << "," if items != ""
			items << "'" + r['item_id'] + "'"
               	}
		##printf("items %s\n",items.inspect())
		if items == ""
			return indices
		end
		query= sprintf("select item_id,key_word,key_words,original_key_words from glossary_indices where lang='%s' and item_id in(%s) ",lang,items)
		splitted.each{|k,s|
			query << sprintf( " and key_words like '%s' " , "%"+@client.escape(k)+"%")
		}
		##printf("QUERY [%s]\n",query)
		res =  @client.query(query)
               	res.each{|r|
			indices[r['item_id']]={
						"lang" => lang,
						"key_words"=>r['original_key_words']
						}
               	}
		return indices
	end
	##
	##
	##
	def key_is_valid(search_keys,keys_found)
		search_keys.each{|sk,sksize|
			matched=false
			keys_found.each{|kf,kfsize|
				simi = WhiteSimilarity.similarity(sk,kf)
				##debug(sprintf("SIMI[%s][%s]%s\n",sk,kf,simi))
				if simi >= 0.8
					##debug(sprintf("MATCHED[%s][%s]%s\n",sk,kf,simi))
					matched=true
					break
				end
			}
			if matched == false
				return false
			end
		}
		return true
	end

	#########################################################################################
	#	INDEXING
	#########################################################################################
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
	def add_phrase_index(lang,phrase)
		##debug(sprintf("add phrase_index %s,%s,%s,%s\n",lang,phrase,@dict_id,@item_id))
        	phrase=remove_notes(phrase,"(",")")
        	phrase=remove_notes(phrase,"{","}")
        	phrase=remove_notes(phrase,"[","]")
		return if phrase==""
		splitted=split_key(phrase)
		return if splitted.size==0
		if phrase.length>250
			phrase=phrase[0,250]
		end
		##debug(sprintf("ADD KEY (%s)(%s)\n",lang,phrase))
		normalized=normalize(phrase)
		phrase = "$phrase$"+ phrase
		if phrase.length>250
			phrase=phrase[0,250]
		end
		splitted.each{|k,s|
			if ignore_key(k)
				printf("IGNORE (%s)\n",k)
				next
			end
			@index << ",\n" if @index.length>0
			@index << sprintf("('%s','%s','%s','%s','%s','%s','%d')\n",
				@client.escape(@dict_id),
				lang,
				@item_id,
				@client.escape(k),
				@client.escape(normalized),
				@client.escape(phrase),
				phrase.length)
		}
		##printf("QUERY %s\n",@index)
	end
	def add_index(lang,key_words)
		##debug(sprintf("add index %s,%s,%s,%s\n",lang,key_words,@dict_id,@item_id))
        	key_words=remove_notes(key_words,"(",")")
        	key_words=remove_notes(key_words,"{","}")
        	key_words=remove_notes(key_words,"[","]")
		return if key_words==""
		key_words.split(';').each{|key|
			####printf("KEY %s\n",key)
			key.gsub!("|",",")
			key.strip!
			next if key==""
			if key.length>250
				next
			end
			##printf("ADD KEY (%s)(%s)\n",lang,key)
			splitted=split_key(key)
			next if splitted.size==0
			normalized=normalize(key)
			splitted.each{|k,s|
				@index << ",\n" if @index.length>0
				@index << sprintf("('%s','%s','%s','%s','%s','%s','%d')\n",
					@client.escape(@dict_id),
					lang,
					@item_id,
					@client.escape(k),
					@client.escape(normalized),
					@client.escape(key),
					key.length)
			}
		}
		##printf("QUERY %s\n",@index)
	end

	def index_init(dict_id)
		@dict_id=dict_id
		@index = ""
	end
	def index_write()
		if @index.length > 0
			res = @client.query(
				sprintf("%s\n","insert into glossary_indices(dict_id,lang,item_id,key_word,key_words,original_key_words,key_len)values\n"+@index))
		end
	end
	def index_entry(item_id,data)
		@item_id=item_id
		data.each{|k,v|
			next if v == ""
			if k.index("TERM:")!=nil
				add_index(k[6,2],v)
				next
			end
			if k.index("PHRASE:")!=nil
				add_phrase_index(k[8,2],v)
				next
			end
		}
	end

	#########################################################################################
	#	UPDATE Dictionary entry
	#########################################################################################


	def update(dict_id,id,data)
		if id==nil or id=="0"
			id=""
		end
		##printf("UPDATE %s \n",id)
		##printf("DATA %s\n",data)
		item_id = hash_dict_entry(dict_id,data)
		##printf("HASH %s\n",item_id)
		old_item_id=""
		if id != ""
			res = @client.query(sprintf(
				"select * from glossaries where id = '%s' limit 1",
				@client.escape(id.to_s)))
			res.each{|r|
				old_item_id=r['item_id']
			}
		end
		##printf("old %s\n",old_item_id)
		if old_item_id != ""
			## update 
			res = @client.query(sprintf(
				"delete from glossary_indices where item_id = '%s' \n",
				@client.escape(old_item_id)))
			res = @client.query(sprintf(
				"update glossaries set dict_id='%s',item_id='%s',data='%s',updated_at=now() where id='%s'\n",
				@client.escape(dict_id),
				@client.escape(item_id),
				@client.escape(JSON.generate(data)),
				@client.escape(id.to_s)))
		else
			## new 
			res = @client.query(sprintf(
				"insert into glossaries(dict_id,item_id,data,created_at,updated_at)values"+
				"('%s','%s','%s',now(),now())\n",
				@client.escape(dict_id),
				@client.escape(item_id),
				@client.escape(JSON.generate(data))))
			res = @client.query(sprintf(
				"select id from glossaries where item_id = '%s' limit 1",
					@client.escape(item_id)))
			res.each{|r|
				id=r['id']
			}
			##printf("ID %s\n",id)
		end
		index_init(dict_id)
		index_entry(item_id,data)
		index_write()
		return id.to_s
	end
end

