require "mysql2"
class GlossaryExportCallback
	def initialize()
	end
	def start(stage,count)
	end
	def sofar(stage,count)
	end
	def done(stage)
	end
	def write(data)
	end
	def finish()
	end
end
class GlossaryExport
	def initialize(cfg,callback)
		@client = Mysql2::Client.new(
			    :host => cfg["host"],
			    :username => cfg["username"], 
			    :password => cfg["password"] , 
			    :database => cfg["database"])
		@callback=callback
	end

	########################################################################

	def count()
		sql  = "select count(distinct key_words) as cnt from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@src_lang)
		sql  << sprintf("dict_id in(%s)",@dicts)
		res = @client.query(sql)
		res.each{|r|
			return r["cnt"]
		}
		return 0
	end
	def get_key_words()
		key_words = []
		sql  = "select distinct key_words from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@src_lang)
		sql  << sprintf("dict_id in(%s) ",@dicts)
		##sql  << sprintf("limit 1000")
		res = @client.query(sql)
		res.each{|r|
			key_words << r["key_words"]
		}
		return key_words
	end
	def build_export_keys(keys)
		ks = ""
		all_keys=Hash.new
		keys.each{|k|
			ks << "," if ks.length>0
			ks << "'"<<@client.escape(k)<<"'"
			all_keys[k.upcase]={
				"key"=>k,
			   	"digest"=>Hash.new,
			   	"translated"=>Hash.new,
			   	"dicts"=>Hash.new
				}
		}
		sql  = "select key_words,digest from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@src_lang)
		sql  << sprintf("dict_id in(%s) and ",@dicts)
		sql  << sprintf("key_words in(%s) ",ks)
		res = @client.query(sql)
		all_digest=Hash.new
		all_digest_set=""
		res.each{|r|
			k = r["key_words"].upcase
			next if all_keys[k]==nil
			digest = r["digest"]
			all_digest[digest]=k
			all_keys[k]["digest"][digest]=digest
			all_digest_set<<"," if all_digest_set.length!=0
			all_digest_set<<"'"<<digest<<"'"
		}
		sql  = "select key_words,digest,dict_id from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@tgt_lang)
		sql  << sprintf("dict_id in(%s) and ",@dicts)
		sql  << sprintf("digest in(%s) ",all_digest_set)
		res = @client.query(sql)
		res.each{|r|
			digest = r["digest"]
			k = all_digest[digest]
			translated = r["key_words"]
			all_keys[k]["translated"][translated]=translated
			all_keys[k]["dicts"][r["dict_id"]]=r["dict_id"]
		}
		return all_keys
	end
	def export_keys(keys)
		data = ""
		all_keys=build_export_keys(keys)
		all_keys.each{|k,v|
			v["translated"].each{|kt,vt|
				data<< sprintf("%s\t%s\n",v["key"],vt)
			}
			#printf("ALLFINAL %s\n%s\n",k,v.inspect())
		}
		@callback.write(data)
	end
	def export_data(src_lang,tgt_lang,dicts)
		
		##printf("%s,%s,%s\n",src_lang,tgt_lang,dicts)
		@src_lang = src_lang
		@tgt_lang = tgt_lang
		##printf("%s\n",dicts.split(",").inspect())
		@dicts=""
		dicts.split(",").each{|d|
			d.strip!
			next if d == ""
			@dicts << "," if @dicts != ""
			@dicts << "'" << d << "'"
		}
		##printf("%s,%s,%s\n",@src_lang,@tgt_lang,@dicts)
		count = count()
		if count==0
		        ### NO KEY
			@callback.finish()
		end
		@callback.start("get-key",count)
		key_words = get_key_words()
		@callback.sofar("get-key",count)
		@callback.done("get-key")
		##printf("K %s\n",key_words.inspect())
		
		cnt = 0
		total = 0
		keys = []
		@callback.start("write-key",count)
		key_words.each{|k|
			cnt += 1
			total += 1
			keys << k
			if cnt == 1000
				@callback.sofar("write-key",total)
				export_keys(keys)
				cnt = 0
				keys = []
			end
		}
		if cnt > 0
			export_keys(keys)
			@callback.sofar("write-key",total)
		end
		@callback.done("write-key")
		@callback.finish()
	end

end

