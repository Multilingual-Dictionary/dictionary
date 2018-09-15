require "mysql2"
require "json"
class GlossaryExportCallback
	def initialize()
	end
	def start(stage,count)
		printf("start %s,%s\n",stage,count)
	end
	def sofar(stage,count)
		printf("sofar %s,%s\n",stage,count)
	end
	def done(stage)
		printf("done %s\n",stage)
	end
	def write(data)
		printf("%s",data)
	end
	def finish()
		printf("finish\n")
	end
	def error(stage,msg)
		printf("error %s,%s\n",stage,msg)
		finish()
	end
end
class GlossaryExport
	def initialize(cfg,callback)
		##printf("INIT CFG %s \n",cfg.inspect())
		@client = Mysql2::Client.new(
			    :host => cfg["host"],
			    :username => cfg["username"], 
			    :password => cfg["password"] , 
			    :database => cfg["database"])
		@callback=callback
		##printf("INIT DONE \n")
	end

	########################################################################
	#	EXPORT TERMS
	########################################################################

	def count()
		sql  = "select count(key_words) as cnt from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@src_lang)
		sql  << sprintf("dict_id in(%s)",@dicts)
		res = @client.query(sql)
		res.each{|r|
			return r["cnt"]
		}
		return 0
	end
	def get_key_words()
		##printf("get key words\n")
		key_words = []
		ofs = 0
		total = 0
		loop do
			##printf("OFS %d\n",ofs)
			sql  = "select distinct key_words from glossary_indices where "
			sql  << sprintf("lang ='%s' and ",@src_lang)
			sql  << sprintf("dict_id in(%s) ",@dicts)
			sql  << sprintf("limit %d,50000",ofs)
			res = @client.query(sql)
			count = 0
			res.each{|r|
				key_words << r["key_words"]
				count = count + 1
				total = total + 1
			}
			break if count==0
			ofs = ofs + count
		end
		##printf(" TOTAL %d\n",total)
		##printf(" SIZE %d\n",key_words.size)
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
			   	"item_id"=>Hash.new,
			   	"translated"=>Hash.new,
			   	"dicts"=>Hash.new
				}
		}
		sql  = "select key_words,item_id from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@src_lang)
		sql  << sprintf("dict_id in(%s) and ",@dicts)
		sql  << sprintf("key_words in(%s) ",ks)
		res = @client.query(sql)
		all_item_id=Hash.new
		all_item_id_set=""
		res.each{|r|
			k = r["key_words"].upcase
			next if all_keys[k]==nil
			item_id = r["item_id"]
			all_item_id[item_id]=k
			all_keys[k]["item_id"][item_id]=item_id
			all_item_id_set<<"," if all_item_id_set.length!=0
			all_item_id_set<<"'"<<item_id<<"'"
		}
		sql  = "select key_words,item_id,dict_id from glossary_indices where "
		sql  << sprintf("lang ='%s' and ",@tgt_lang)
		sql  << sprintf("dict_id in(%s) and ",@dicts)
		sql  << sprintf("item_id in(%s) ",all_item_id_set)
		res = @client.query(sql)
		res.each{|r|
			item_id = r["item_id"]
			k = all_item_id[item_id]
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
	def export_terms(src_lang,tgt_lang,dicts)
		
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
		##printf("count %s\n",count)
		
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
		count=key_words.size
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
	########################################################################
	#	EXPORT GLOSSARY
	########################################################################

	def json_parse(data)
		begin
			ret=JSON.parse(data)
		rescue
			return nil
		end
	end

	def export_glossary(dict_id)

		## GET-DICT-INFOS

		@stage="get-infos"
		@callback.start(@stage,1)
		res = @client.query(sprintf(
			"select *  from dict_configs where dict_sys_name='%s' limit 1", 
			 @client.escape(dict_id)))
		@dict_infos=nil
		res.each{|r|
			@dict_infos=r
			break
		}
		if @dict_infos==nil
			@callback.error(@stage,sprintf("Infos for [%s] not found",dict_id))
			return
		end
		##printf("%s\n",@dict_infos.inspect())
		if @dict_infos["cfg"]==nil
			@callback.error(@stage,sprintf("Infos[cfg] for [%s] not exists",dict_id))
			return
		end
		@cfg=json_parse(@dict_infos["cfg"])
		if @cfg==nil
			@callback.error(@stage,sprintf("Infos[cfg] for [%s] is bad!(!json)",dict_id))
			return
		end
		if @cfg["config"]==nil
			@callback.error(@stage,sprintf("cfg[config] for [%s] not exists!",dict_id))
			return
		end
		if @cfg["config"]["languages"]==nil
			@callback.error(@stage,sprintf("cfg[config][languages] for [%s] not exists!",dict_id))
			return
		end
		@cfg_languages=@cfg["config"]["languages"]
		##printf("cfglang %s\n",@cfg_languages.inspect())
		@callback.done(@stage)

		@stage="exporting"

		res = @client.query(sprintf(
			"select count(*) as cnt from glossaries where dict_id='%s' limit 1", 
			 @client.escape(dict_id)))
		count=0
		res.each{|r|
			count=r['cnt']
			break
		}
		#####################################
		@callback.start(@stage,count)
		@callback.write(sprintf("#DICT_INFOS\t#########\n"))
		@callback.write(sprintf("#DICT_ID\t%s\n",@dict_infos["dict_sys_name"]))
		@callback.write(sprintf("#DICT_NAME\t%s\n",@dict_infos["dict_name"]))
		@callback.write(sprintf("#DICT_DESC\t%s\n",@dict_infos["desc"]))
		@callback.write(sprintf("#DICT_CREATED_AT\t%s\n",@dict_infos["created_at"]))
		@callback.write(sprintf("#DICT_UPDATED_AT\t%s\n",@dict_infos["updated_at"]))
		@callback.write(sprintf("#COLDEFS\n"))
		cols=[]
		@cfg_languages.each{|tag,col|
			i_col=col.to_i
			next if i_col<0
			cols[i_col]=tag
		}
		if cols.size==0
			@callback.error(@stage,sprintf("cfg[config][languages] for [%s] is bad!",dict_id))
			return
		end
		line=""
		cols.each{|tag,i|
			if tag==nil
				line <<"\t"
			else
				line << tag +"\t"
			end
		}
		line << "\n"
		@callback.write(line)
		
		#####################################


		ofs=0
		total=0
		loop do
			##printf("OFS %d\n",ofs)
			data=""
			res = @client.query(sprintf(
				"select data from glossaries where dict_id='%s' limit %d,1000",
			 		@client.escape(dict_id),
					ofs))
			count = 0
			lines=""
			res.each{|r|
				count = count + 1
				ofs = ofs + 1
				d=json_parse(r["data"])
				next if d == nil
				line=""
				cols.each{|tag,i|
					if tag==nil or d[tag]==nil
						line <<"\t"
						next
					else
						line << d[tag] +"\t"
					end
				}
				lines << line + "\n"
			}
			@callback.write(lines) 
			total += count
			@callback.sofar(@stage,total)
			break if count==0
		end
		@callback.done(@stage)
		@callback.finish()
	end

end

