require 'tempfile'
require 'iconv'
require 'roo'
require 'roo-xls'

class DavDictPagesController < ApplicationController
  def do_import(file)
	begin
		tmp_name = "/tmp/"+file.original_filename
		tmp_file = File.new(tmp_name,"wb")
		tmp_file.write(file.read)
		tmp_file.close()
		workbook = Roo::Excel.new(tmp_name)
		File::unlink(tmp_name)
		### OK we have data !
		sheet= workbook.sheet(0)
		sheet.each {|r|
			record= DavkhktDict.new
			record.key_words = r[0].to_s
			record.wtype = r[1].to_s
			record.category = r[2].to_s
			record.english = r[3].to_s
			record.viet = r[4].to_s
			if record.record_exists()
				puts "EXIST"
			else
				puts "SAVE"
				record.save
			end
		}
	rescue Exception => e
		puts e.message
	end
  end
  def import
	printf("IMPORT \n");
	if params[:commit]=='import' and params[:import_file] != nil 
		do_import(params[:import_file]) 
	end
  end

  def show
  end
end
