#########################################################################################
##	GLOSSARY LIB 
#########################################################################################

require "unicode_utils/casefold"

class GlossaryLib
	attr_accessor :client

	#########################################################################################
	##	INIT
	#########################################################################################

	def initialize(cfg=nil)
		##printf("INIT %s\n",cfg.inspect())
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
	##  split key ( for indexing) 
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

	#########################################################################################
	#	SEARCH INDICES
	#########################################################################################

	def search_indices(key,dict_id,lang,search_mode)
		indices = Hash.new
		splitted=split_key(key)
		normalized=normalize(key)
		if splitted.size==0
			return indices
		end
		dict_cond=""
    		dict_id.split(",").each{|d|
      			dict_cond << "," if dict_cond!=""
      			dict_cond << "'"+@client.escape(d)+"'"
    		}
		dict_cond = sprintf("dict_id in (%s) ",dict_cond) if dict_cond != ""
		cond = " 1 "
		if dict_cond != ""
			cond << "\n and ( " + dict_cond + ") "
		end

		###
		###  query dbase with this condition

		if search_mode != 'search_contain'
			#### SEARCH-EXACT
			query= sprintf("select original_key_words,item_id from glossary_indices where %s ",cond)
			query <<  " and " + sprintf( "lang = '%s' ",lang)
                        query <<  " and " + sprintf( "key_words = '%s' ",@client.escape(normalized))
			res =  @client.query(query)
                	res.each{|r|
                        	indices[r['item_id']]={
						"lang" => lang,
						"key_words"=>r['original_key_words']
						}
                	}
			return indices
		end

		###  SEARCH - CONTAIN

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
		res =  @client.query(query+ "order by key_len limit 50")
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
	def add_index(lang,key_words)
		##printf("add index %s,%s,%s,%s\n",lang,key_words,@dict_id,@item_id)
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
			next if k.index("TERM:")==nil
			add_index(k[6,2],v) if v !=""
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

