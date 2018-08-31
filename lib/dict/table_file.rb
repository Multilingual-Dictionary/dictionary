require 'iconv'
require 'roo'
require 'roo-xls'

class TableFile
	attr_accessor :error,:num_rows,:table
	def initialize(file)
		@error=""
		@file_is=nil
		@table=nil
		begin
			workbook = Roo::Excel.new(file)
		rescue Exception => e
			workbook = nil
			@error << e.to_s
	   	end
		if workbook != nil
			@error=nil
			return excel_init(workbook)
		end
		begin
			workbook = Roo::Excelx.new(file)
		rescue Exception => e
			workbook = nil
			@error << e.to_s 
	   	end
		if workbook != nil
			@error=nil
			return excel_init(workbook)
		end
		begin
			@table= CSV.read(file)
		rescue Exception => e
			workbook = nil
			@error << e.to_s
		end
		if @table != nil
			@file_is="csv"
			@error=nil
			return csv_init
		end
		return self
	end
	def excel_init(workbook)
		@sheet= workbook.sheet(0)
		@num_rows=@sheet.last_row-@sheet.first_row+1
		@table=[]
		@sheet.each{|r|
			@table << r
		}
		return self
	end
	def csv_init
		@num_rows=@table.size
		return self
	end
end



##wb = TableFile.new(ARGV[0])
##if wb.error!=nil
##	exit(0)
##end
##printf("%s\n",wb.workbook.inspect())
##printf("num rows %s\n",wb.num_rows)
##printf("table %s\n",wb.table.inspect())


