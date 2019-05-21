require "mysql2"
require 'iconv'
require 'json'
require 'roo'
require 'roo-xls'
require_relative 'table_file'
require_relative 'glossary'

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
	def initialize(glossary_lib=nil,dict_id=nil,tags=nil,item_data=nil,category=nil)
		if glossary_lib != nil
			@dict_id = dict_id
			@item_id = ''
			@data = Hash.new
			tags.each{|k,col|
				v = item_data[col.to_i].to_s
				v = "" if  v==nil
				v.strip!
				@data[k]=v 
			}
			if category!=nil
				@data["#CATEGORY"]=category
			end
			@item_id = glossary_lib.hash_dict_entry(dict_id,@data)
		end
	end
	def setup_with_json(glossary_lib,dict_id,data)
		@dict_id = dict_id
		@data = data
		@item_id = glossary_lib.hash_dict_entry(dict_id,@data)
	end
end

class GlossaryImport
	attr_accessor :dict_name,:author,:category,:year,:glossary
	def initialize(cfg=nil,callback=nil)
		@dict_name=""
		@author=""
		@category=nil
		@year=""
		if cfg!=nil 
			@client = Mysql2::Client.new(
			    :host => cfg["host"],
			    :username => cfg["username"], 
			    :password => cfg["password"] , 
			    :database => cfg["database"])
		end
		@glossary=GlossaryLib.new(cfg)
		if callback != nil
			@callback=callback
		else
			@callback=GlossaryImportCallback.new
		end
	end
	def is_numeric(txt)
		return txt.to_s.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil ? false : true
	end
	###
 	###	Import array of records
	###
	def import_records(recs)

		##printf("IMPORT %s \n",recs.length)
		##printf("IMPORT_DATA %s \n",recs.inspect())

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

		@glossary.index_init(@dict_id)
		recs.each{|dg,r|
			@glossary.index_entry(r.item_id,r.data)
		}
		@glossary.index_write()

	end

	##
	##  read file in
	##

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
			break if i > 50
			case first 
			when "#DICTNAME"
				@dict_name=get_value(r[1])
			when "#AUTHOR"
				@author=get_value(r[1])
			when "#FIELD"
				@category=get_value(r[1])
			when "#CATEGORY"
				@category=get_value(r[1])
			when "#DOMAIN"
				@category=get_value(r[1])
			when "#YEAR"
				@year=get_value(r[1])
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
			break if count >= 20
		end
		format["DATA_START"]=i+3
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
			i_row= fmt["DATA_START"].to_i-1
			i_row= 0 if i_row < 0 
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
			break if count >=  20
		end
		if fmt["DATA_START"] == nil
			format["DATA_START"] = 1
		else
			format["DATA_START"] = fmt["DATA_START"]
		end
		format["SOME_DATAS"]=datas
		return format
	end
	def json_parse(data)
		begin
			ret=JSON.parse(data)
		rescue
			return nil
		end
	end
	def import_json(file,params)
		@dict_id=params["dict_id"].upcase.strip
		begin
			f = File.open(file)
			recs = Hash.new
			count = 0
			while line=f.gets()
				count = count + 1
				d = json_parse(line)
				next if d == nil
				data = GlossaryData.new()
				data.setup_with_json(@glossary,@dict_id,d)
				recs[data.item_id]=data
				if recs.length>=1000
					import_records(recs)
					recs.clear()
				end
			end
			if recs.length>0
				import_records(recs)
				@callback.sofar("importing",count)
			end
		rescue Exception => e
			# @callback.error("importing",sprintf("import error %s",e))
		end
		@callback.done("importing")
		@callback.finish()
	end
	def import(file,params,fmt=nil)
		if params["format"] != nil and params["format"] == "json"
			return import_json(file,params)
		end
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
		printf("CATEOGY %s\n",@category)
		@format.each{|k,col|
			next if k[0] != "#"
			tags[k]=col.to_i
			if k.index("#CATEGORY")!=nil
				@category=nil
			end
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
				if r[0] != nil
					v0 =get_value(r[0])
					next if v0[0,1]=="#"
				end
				data = GlossaryData.new(@glossary,@dict_id,tags,r,@category)
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

