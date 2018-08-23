
####require './lib/dict/glossary_import'
require 'iconv'
require 'roo'
require 'roo-xls'


class ImportGlossaryJob < ApplicationJob
  queue_as :urgent
  attr_accessor :key_words,:word_type,:category,:primary_xlate,:secondary_xlate

  def perform(id,dict_id,data_file,params)
    printf("DO IMPORT id %s, dict_id %s,data_file %s\n",
			id,dict_id,data_file)
    printf("PARAMS %s\n",params.inspect())
    setup(params)
    
    ## start job now
    start(id,"import_glossary")
    @job.update( status: "in_progress")
    @job.update( stage: "reading file")
    @job.update( message: "reading file , please wait")
    @job.update( percent: 0)
    begin
      workbook = Roo::Excel.new(data_file)
      sheet= workbook.sheet(0)
      num_rows=sheet.last_row-sheet.first_row+1
      if num_rows <= 0
        @job.update( percent: 100)
        @job.update( status: 'done')
        @job.update( message: 'no data!')
        return
      end
      printf("NUM %s\n",num_rows)
	  processed=0
      @job.update(stage: "importing")
      @job.update( message: sprintf("0 of %s processed [%s]",processed,"0%"))
      count=0
      sheet.each {|r|
        record= get_from_excel(r,params)
        record.dict_id = dict_id
        record.setup_record()
	##printf("%s\n",record.inspect())
        if ( record.add_if_not_exists() == 1)
          record.index_keys(params['config'])
        end
        count += 1
        processed += 1
        if count == 100
	  count = 0
          printf("%s from %s\n",processed,num_rows)
          percent = (processed.to_i*100)/num_rows.to_i
          msg = sprintf("%s of %s processed [%s]",processed,num_rows,percent.to_s+"%")
          @job.update( percent: percent)
          @job.update( message: msg)
        end
      }
      percent = (processed.to_i*100)/num_rows.to_i
      msg = sprintf("%s of %s processed [%s]",processed,num_rows,percent.to_s+"%")
      @job.update(percent: 100)
      @job.update( message: msg)
      @job.update( status: 'done')
      File::unlink(data_file)
    rescue Exception => e
        @job.update( message: e.message)
		@job.update( status: 'error')
    end
  end

  def is_numeric(txt)
    return txt.to_s.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil ? false : true
  end

  def setup(params)
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

  def get_from_excel(r,params)
    rec= Glossary.new
    rec.key_words = r[@key_words].to_s
    rec.word_type= r[@word_type].to_s if @word_type != nil
    rec.category= r[@category].to_s if @category != nil
    rec.primary_xlate= r[@primary_xlate].to_s 
    rec.secondary_xlate= r[@secondary_xlate].to_s if @secondary_xlate != nil
    return rec
  end



end

### Call back 

class MyGlossaryImportCallback
	def initialize(job,file)
	end
	def start(stage,count)
	end
	def write(data)
	end
	def sofar(stage,count)
	end
	def done(stage)
	end
	def finish()
	end
end


