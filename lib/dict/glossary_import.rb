require "mysql2"
require 'iconv'
require 'json'
require 'roo'
require 'roo-xls'
require_relative 'table_file'

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
	def warn(stage,msg)
		printf("CALLBACK WARN %s,%s \n",stage,msg)
	end
	def finish()
		printf("CALLBACK FINISH \n")
	end
end

class GlossaryData
	attr_accessor :dict_id,:item_id,:data
	
	def initialize(dict_id,tags,item_data)
		md5 = Digest::MD5.new
		md5 << dict_id.upcase
		@dict_id = dict_id
		@item_id = ''
		@data = Hash.new
		tags.each{|k,col|
			v = item_data[col.to_i].to_s
			v = "" if  v==nil
			v.strip!
			@data[k]=v 
			md5 << v.upcase
		}
		@item_id = md5.hexdigest
	end
end
class GlossaryImport
	def initialize(cfg=nil,callback=nil)
		if cfg!=nil 
			@client = Mysql2::Client.new(
			    :host => cfg["host"],
			    :username => cfg["username"], 
			    :password => cfg["password"] , 
			    :database => cfg["database"])
		end
		if callback != nil
			@callback=callback
		else
			@callback=GlossaryImportCallback.new
		end
	end
	def is_numeric(txt)
		return txt.to_s.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil ? false : true
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
		##printf("add index %s,%s,%s,%s\n",lang,key_words,@dict_id,@item_id)
        	key_words=remove_notes(key_words,"(",")")
        	key_words=remove_notes(key_words,"{","}")
        	key_words=remove_notes(key_words,"[","]")
		return if key_words==""
		key_words.gsub(/;/,",").split(',').each{|key|
			####printf("KEY %s\n",key)
			key.strip!
			next if key==""
			if key.length>250
				@callback.warn("index-file",sprintf(
						"key very long! ignored!%s\n",key))
				next
			end
			@index << ",\n" if @index.length>0
			##printf("ADD KEY (%s)(%s)\n",lang,key)
			@index << sprintf("('%s','%s','%s','%s','%d',now(),now())\n",
					@client.escape(@dict_id),
					lang,
					@item_id,
					@client.escape(key),
					key.length)
		}
		##printf("QUERY %s\n",@index)
	end
	def index_keys(r)
		@item_id=r.item_id
		r.data.each{|k,v|
			next if k.index("TERM:")==nil
			add_index(k[6,2],v) if v !=""
		}
	end
	###
 	###	Import array of records
	###
	def import_records(recs)

		##printf("IMPORT %s \n",recs.length)
		d = "''"
		recs.each{|dg,r|
			d << ",'"+dg+"'"
		}
		##
		## check if already exists ? ( using item_id , for now is md5 hash of the data )
		##
		query="select item_id from glossaries where item_id in ("+d+")"
		res = @client.query(query)
		res.each{|r|
			##printf("r %s\n",r.inspect())
			v = recs.delete(r["item_id"])  ## we dont need to import this!
		}
		return if recs.length==0
		##
		## import -> glossaries-table
		##
		query = "insert into glossaries(dict_id,item_id,data,created_at,updated_at)values\n"
		i = 0
		recs.each{|dg,r|
			if i > 0
				query << ",\n"
			end
			i = i + 1
			query << sprintf("('%s','%s','%s',now(),now())\n",
					@client.escape(r.dict_id),
					@client.escape(r.item_id),
					@client.escape(JSON.generate(r.data)))
		}
		res = @client.query(query)

		##
		## index now
		##
		@index=""
		recs.each{|dg,r|
			index_keys(r)
		}
		if @index.length > 0
			res = @client.query(
			  	"insert into glossary_indices(dict_id,lang,item_id,key_words,key_len,created_at,updated_at)values\n"+@index)
		end
	end
	def read_file(file)
		@callback.start("read-file",0)
		@workbook = TableFile.new(file)
		if @workbook.error!=nil
			@callback.error("read-file",sprintf("could not read %s,error %s",file,@workbook.error))
			@callback.done("read-file")
			@callback.finish()
			return @workbook.error
		end
		@callback.done("read-file")
		return nil
	end
	##
	def get_tag(v)
		return "" if v==nil
		value=v.to_s.strip.upcase.gsub(/ /,"").to_s
		if value[0]=='#'
			return v
		end
		return ""
	end
	def get_value(v)
		return "" if v==nil
		return v.to_s.strip
	end
	### detect if is our format?
	def detect_our_format()
		i = -1
		coldefs=nil
		@workbook.table.each {|r|
			i += 1
			first=get_tag(r[0])
			if first=="#COLDEFS"
				coldefs=first
				break
			end
		}
		return nil if coldefs==nil
		defs = @workbook.table[i+1]
		j = -1  
		format = Hash.new
		defs.each{|d|
			j += 1
			v = get_tag(d)
			next if v == ""
			format[v]=j
		}
		return nil if format.size == 0
		datas=[]
		i_row = i+1
		count = 0
		while i_row < @workbook.table.size
			r =@workbook.table[i_row]
			i_row += 1
			break if r == nil
			next if get_tag(r[0]) != ""
			count += 1
			d = Hash.new
			format.each{|k,col|
				d[k]=get_value(r[col.to_i])
			}
			datas << d
			break if count >= 4
		end
		format["DATA_START"]=i+2
		format["SOME_DATAS"]=datas
		return format
	end
	def detect_format()
		fmt = detect_our_format()
		return fmt if fmt != nil
		return nil
	end
	def pre_read(file,fmt=nil)
		res = read_file(file)
		return nil if res !=nil
		format=detect_format()
		if format != nil
			format["FMT_IN_FILE"]=1
			return format 
		end
		return nil if fmt==nil
		## 
		format = Hash.new
		fmt.each{|k,col|
			next if k[0] != "#"
			c = col.to_s.strip
			next if c==""
			format[k]=c.to_i
		}
		if fmt["DATA_START"] != nil
			i_row= fmt["DATA_START"].to_i
		else
			i_row=0
		end
		datas=[]
		count = 0
		
		while i_row < @workbook.table.size
			r =@workbook.table[i_row]
			i_row += 1
			break if r == nil
			next if get_tag(r[0]) != ""
			count += 1
			d = Hash.new
			format.each{|k,col|
				d[k]=get_value(r[col.to_i])
			}
			datas << d
			break if count >= 4
		end
		if fmt["DATA_START"] == nil
			format["DATA_START"] = 0
		else
			format["DATA_START"] = fmt["DATA_START"]
		end
		format["SOME_DATAS"]=datas
		return format
	end
	def import(file,params,fmt=nil)
		res = read_file(file)
		return res if res !=nil
		num_rows=@workbook.num_rows
		if num_rows <= 0
			@callback.error("read-file",sprintf("empty file ! %s",file))
			@callback.done("read-file")
			@callback.finish()
			return
		end
		@format=detect_format()
		## if format in file , use it
		if @format==nil
			## not in file
			if fmt==nil
				## and not specified!
				@callback.error("read-file",sprintf("format not supported ! %s",file))
				@callback.done("read-file")
				@callback.finish()
				return
			end
			## yes , it is specified
			@format=fmt
			printf("USE SPEC FMT %s\n",@format.inspect())
		else	
			printf("USE FILE FMT %s\n",@format.inspect())
		end

		## prepare , get tags from format

		@dict_id=params["dict_id"].upcase.strip
		tags = Hash.new
		@format.each{|k,col|
			next if k[0] != "#"
			tags[k]=col.to_i
		}
		## import now
		@callback.start("importing",num_rows)
		begin 
			count = 0
			recs = Hash.new
			n = 0
			count = 0
			i_row = @format["DATA_START"].to_i
			while i_row < @workbook.table.size
				r =@workbook.table[i_row]
				i_row += 1
				n += 1
				count += 1
				if (n == 100)
					n= 0
					@callback.sofar("importing",count)
				end
				data = GlossaryData.new(@dict_id,tags,r)
				recs[data.item_id]=data
				if recs.length>=100
					import_records(recs)
					recs.clear()
				end
			end
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

