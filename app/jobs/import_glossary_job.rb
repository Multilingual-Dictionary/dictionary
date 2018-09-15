
require './lib/dict/glossary_import'

class ImportGlossaryJob < ApplicationJob
	queue_as :urgent

	def perform(id,dict_id,data_file,format)
    	printf("DO IMPORT id %s, dict_id %s,data_file %s\n",id,dict_id,data_file)
		printf("FORMAT %s\n",format.inspect())
		## start job now
		start(id,"import_glossary")
		@job.update(status: "in_progress")
		@job.update(in_data: File.basename(data_file))
		@job.update(notes: sprintf("Import %s",dict_id))
		## use sql
        	db_config= YAML::load(File.open('config/database.yml'))
		##
		callback= MyGlossaryImportCallback.new(@job)
		imp= GlossaryImport.new(
                      {
                        "host" => "localhost",
                        "username" => db_config[Rails.env]["username"],
                        "password" =>db_config[Rails.env]["password"],
                        "database" =>db_config[Rails.env]["database"]
                      },
                      callback)
        	imp.import(	data_file, 
						{"dict_id"=>dict_id }, 
						format)
	end

end

### Call back 

class MyGlossaryImportCallback
	attr_accessor :job,:total,:sofar,:stage,:warning,:error,:percent
	def initialize(job)
		@warning = []
		@error=""
		@job = job
		@total = 0
		@sofar = 0
		@percent= 0
	end
	def start(stage,count)
		printf("START %s,%s\n",stage,count)
		@total = count
		@stage = stage
		@job.update( stage: stage)
	end
	def sofar(stage,count)
		##printf("SOFAR ---%s,%s,%s\n",stage,count,@total)
		@stage = stage
		@sofar = count
		if @total <=  0
			@percent = 0
		else
			@percent = (@sofar.to_i*100)/@total.to_i
		end
		##printf("SOFAR %s,%s,%s,%s\n",stage,@sofar,@total,@percent)
		msg = sprintf("%s of %s imported [%s]",@sofar,@total,@percent.to_s+"%")
		@job.update( percent: @percent)
		@job.update( message: msg)
		@job.update( stage: stage)
		##printf("COUNT %s,%s,%s\n",stage,count,msg)
	end
	def done(stage)
		@stage = stage
		@job.update( percent: 100)
		@job.update( stage: stage)
		printf("DONE %s\n",stage)
	end
	def warn(stage,msg)
		printf("WARN %s\n",msg)
		@stage = stage
		@warning << msg
	end
	def error(stage,msg)
		@stage = stage
		@error=msg
		@job.update( percent: 100)
	end
	def finish()
		printf("FINISH\n")
		@job.update( percent: 100)
		if @error == ""
			@job.update( status: 'done')
			msg = ""
			len =0
			@warning.each{|w|
				len = len + w.length
				break if len > 200
				msg << w + "\n"
			}
			msg << sprintf("Đã nhập %s từ mục\n",@sofar)
			printf("FINISH %s\n",msg)
			@job.update( message: msg)
		else
			@job.update( status: 'error')
			@job.update( message: @error)
		end
	end
end



