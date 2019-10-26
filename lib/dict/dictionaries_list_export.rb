require "mysql2"
require "rubyXL"
class DictionaryListExport
	def initialize(cfg)
		##printf("INIT CFG %s \n",cfg.inspect())
		@client = Mysql2::Client.new(
			    :host => cfg["host"],
			    :username => cfg["username"], 
			    :password => cfg["password"] , 
			    :database => cfg["database"])
		##printf("INIT DONE \n")
	end

	def do_export(file)
		workbook = RubyXL::Workbook.new
		sheet1 = workbook[0]
		res = @client.query("select *  from dict_configs ")
		row = 0
		sheet1.add_cell(row,0,"ID")
		sheet1.add_cell(row,1,"Ten He Thong")
		sheet1.add_cell(row,2,"Ten Tu Dien")
		sheet1.add_cell(row,3,"Ngon Ngu")
		sheet1.add_cell(row,4,"Dien Giai")
		sheet1.add_cell(row,5,"Infos")
		sheet1.add_cell(row,6,"Protocol")
		sheet1.add_cell(row,7,"ConfigPara")
		row = 1
		res.each{|r|
			sheet1.add_cell(row,0,r["id"])
			sheet1.add_cell(row,1,r["dict_sys_name"])
			sheet1.add_cell(row,2,r["dict_name"])
			sheet1.add_cell(row,3,r["lang"])
			sheet1.add_cell(row,4,r["desc"])
			sheet1.add_cell(row,5,r["ext_infos"])
			sheet1.add_cell(row,6,r["protocol"])
			sheet1.add_cell(row,7,r["cfg"])
			row = row + 1
		}
		workbook.write(file)
	end
end

def test_DictionaryListExport()

	host=	ENV["DB_HOST"]
	username=ENV["DB_USER"]
	password=ENV["DB_PASSWORD"]
	database=ENV["DB_DBASE"]

	host=	"localhost" if host==nil
	username="root" if username==nil
	password="letien1512" if password==nil
	database="dictionary_development" if database==nil

	exp=DictionaryListExport.new(
		{"host" =>host,
		 "username" => username, 
		 "password" => password, 
		 "database" => database
		})
	exp.do_export("./test.xlsx")
end
##test_DictionaryListExport()
