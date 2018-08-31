require "mysql2"
require 'iconv'
require 'roo'
require 'roo-xls'

class GlossaryImportCallback
	def initialize()
	end
	def start(stage,count)
		@total=count
		printf("CALLBACK START %s, COUNT %s\n",stage,count)
	end
	def sofar(stage,count)
		printf("CALLBACK SOFAR %s, COUNT %s FROM %s \n",stage,count,@total)
	end
	def done(stage)
		printf("CALLBACK DONE %s, \n",stage)
	end
	def error(stage,msg)
		printf("CALLBACK ERROR %s,%s \n",stage,msg)
	end
	def finish()
		printf("CALLBACK FINISH\n")
	end
end

class Glossary
	attr_accessor :dict_id,:key_words, :category, :word_type,
		:primary_xlate, :secondary_xlate,:digest
	def initialize(dict_id)
		@dict_id = dict_id.strip
		@key_words = ''
		@key_words = ''
		@category= ''
		@word_type= ''
		@primary_xlate= ''
		@secondary_xlate= ''
		@digest= ''
	end
end
class GlossaryImport
	def initialize(cfg,callback)
		@client = Mysql2::Client.new(
			    :host => cfg["host"],
			    :username => cfg["username"], 
			    :password => cfg["password"] , 
			    :database => cfg["database"])
		@callback=callback
	end
	def is_numeric(txt)
		return txt.to_s.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil ? false : true
	end
	def setup(params)
		@cfg=params
		@dict_id=params["dict_id"].upcase.strip
		if is_numeric(params["key_words"])
			@key_words = params["key_words"].to_i
		else
			@key_words = 0
		end
		if is_numeric(params["word_type"])
			@word_type=params["word_type"].to_i
		else
			@word_type=nil
		end
		if is_numeric(params["category"])
			@category=params["category"].to_i
		else
			@category=nil
		end
		if is_numeric(params["primary_xlate"])
			@primary_xlate=params["primary_xlate"].to_i
		else
			@primary_xlate=1
		end
		if is_numeric(params["secondary_xlate"])
			@secondary_xlate=params["secondary_xlate"].to_i
		else
			@secondary_xlate=nil
		end
  	end
	def get_from_excel(r)
		rec= Glossary.new(@dict_id)
		rec.key_words = r[@key_words].to_s.strip
		rec.word_type= r[@word_type].to_s.strip if @word_type != nil
		rec.category= r[@category].to_s.strip if @category != nil
		rec.primary_xlate= r[@primary_xlate].to_s.strip 
		rec.secondary_xlate= r[@secondary_xlate].to_s.strip if @secondary_xlate != nil

		return nil if rec.key_words.length ==0
		return nil if rec.word_type.length > 60
		return nil if rec.category.length > 60
		return nil if rec.primary_xlate.length ==0 and 
		              rec.secondary_xlate.length ==0 

		md5 = Digest::MD5.new
		md5 << rec.dict_id
		md5 << rec.key_words
		md5 << rec.word_type
		md5 << rec.category
		md5 << rec.primary_xlate
		md5 << rec.secondary_xlate
		rec.digest = md5.hexdigest
		return rec
	end

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
		##printf("add index %s,%s,%s,%s\n",lang,key_words,@dict_id,@digest)
        	key_words=remove_notes(key_words,"(",")")
        	key_words=remove_notes(key_words,"{","}")
        	key_words=remove_notes(key_words,"[","]")
		return if key_words==""
		key_words.gsub(/;/,",").split(',').each{|key|
			####printf("KEY %s\n",key)
			key.strip!
			next if key==""
			next if key.length>250
			@index << ",\n" if @index.length>0
			##printf("ADD KEY (%s)(%s)\n",lang,key)
			@index << sprintf("('%s','%s','%s','%s','%s',now(),now())\n",
					@client.escape(@dict_id),
					lang,
					@digest,
					@client.escape(key),
					key.length)
		}
		##printf("QUERY %s\n",@index)
	end

	def index_keys(r)
		@digest=r.digest
		add_index(@cfg["key_words_lang"],r.key_words) if @cfg["key_words_lang"]!=""
		add_index(@cfg["primary_xlate_lang"],r.primary_xlate) if @cfg["primary_xlate_lang"]!=""
		add_index(@cfg["secondary_xlate_lang"],r.secondary_xlate) if @cfg["secondary_xlate_lang"]!=""
	end
	def import_records(recs)
		##printf("IMPORT %s \n",recs.length)
		d = "''"
		recs.each{|dg,r|
			d << ",'"+dg+"'"
		}
		query="select digest from glossaries where digest in ("+d+")"
		res = @client.query(query)
		res.each{|r|
			##printf("r %s\n",r.inspect())
			v = recs.delete(r["digest"])
		}
		return if recs.length==0
		##printf("IMPORT %s NOW\n",recs.length)
		query = "insert into glossaries(dict_id,key_words,word_type,category,primary_xlate,secondary_xlate"+
			",digest,created_at,updated_at)values\n"
		i = 0
		recs.each{|dg,r|
			if i > 0
				query << ",\n"
			end
			i = i + 1
			query << sprintf("('%s','%s','%s','%s','%s','%s','%s',now(),now())\n",
					@client.escape(r.dict_id),
					@client.escape(r.key_words),
					@client.escape(r.word_type),
					@client.escape(r.category),
					@client.escape(r.primary_xlate),
					@client.escape(r.secondary_xlate),
					@client.escape(r.digest))
		}
		##printf("QUERY %s\n",query)
		res = @client.query(query)
		@index=""
		recs.each{|dg,r|
			index_keys(r)
		}
		if @index.length > 0
			res = @client.query(
			  	"insert into glossary_indices(dict_id,lang,digest,key_words,key_len,created_at,updated_at)values\n"+@index)
		end
	end
	def import(file,params)
		printf("para %s\n",params.inspect())
		@callback.start("read-file",0)
		begin
			workbook = Roo::Excel.new(file)
		rescue Exception => e
			@callback.error("read-file",sprintf("could not read %s",file))
			@callback.done("read-file")
			@callback.finish()
			return
	   	end
		@callback.done("read-file")
		sheet= workbook.sheet(0)
		num_rows=sheet.last_row-sheet.first_row+1
		if num_rows <= 0
			@callback.error("read-file",sprintf("empty file ! %s",file))
			@callback.done("read-file")
			@callback.finish()
			return
		end
		@callback.start("importing",num_rows)
		begin 
			count = 0
			setup(params)
			recs = Hash.new
			n = 0
			count = 0
			sheet.each {|r|
				n += 1
				count += 1
				if (n == 100)
					n= 0
					@callback.sofar("importing",count)
				end
				rec = get_from_excel(r)
				if rec==nil
					next
				end
				recs[rec.digest]=rec
				if recs.length>=100
					import_records(recs)
					recs.clear()
				end
			}
			if recs.length>0
				import_records(recs)
				@callback.sofar("importing",count)
			end
		rescue Exception => e
			@callback.error("importing",sprintf("import error %s",e))
		end
		@callback.done("importing")
		@callback.finish()
	end
end

