require "unicode_utils/casefold"
###

class GlossaryLib
	attr_accessor :client
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

	def normalize(key)
		return UnicodeUtils.casefold(key).gsub(/\p{^Alnum}/,"")
	end

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
			q = sprintf("select item_id from %s where lang='%s' and key_word like '%s'\n",
				'glossary_indices',
				lang,
				@client.escape(k)+"%")
			if query==""
				query = q 
			else
				query = q + " and item_id in (" + query +")" + "\n"
			end
		}
		printf("QUERY [%s]\n",query)
		res =  @client.query(query+ " limit 100")
		items = ""
               	res.each{|r|
			items << "," if items != ""
			items << "'" + r['item_id'] + "'"
               	}
		if items == ""
			return indices
		end
		query= sprintf("select item_id,key_word,key_words,original_key_words from glossary_indices where lang='%s' and item_id in(%s) ",lang,items)
		splitted.each{|k,s|
			query << sprintf( " and key_words like '%s' " , "%"+@client.escape(k)+"%")
		}
		printf("QUERY [%s]\n",query)
		res =  @client.query(query)
               	res.each{|r|
			indices[r['item_id']]={
						"lang" => lang,
						"key_words"=>r['original_key_words']
						}
               	}
		return indices
	end
end

