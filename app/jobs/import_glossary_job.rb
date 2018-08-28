
require './lib/dict/glossary_import'

class ImportGlossaryJob < ApplicationJob
	queue_as :urgent

	def perform(id,dict_id,data_file,params)
    		printf("DO IMPORT id %s, dict_id %s,data_file %s\n",
			id,dict_id,data_file)
		import_params={
			"dict_id"=>dict_id,
                	"key_words_lang"=>params["config"]["key_words_lang"],
                	"primary_xlate_lang"=>params["config"]["primary_xlate_lang"],
                	"secondary_xlate_lang"=>params["config"]["secondary_xlate_lang"],
                	"key_words"=>params["key_words"],
                	"word_type"=>params["word_type"],
                	"category"=>params["category"],
                	"primary_xlate"=>params["primary_xlate"],
                	"secondary_xlate"=>params["secondary_xlate"]
                	} 
		## start job now
		start(id,"import_glossary")
		@job.update(status: "in_progress")
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
        	imp.import(data_file,import_params)
	end

end

### Call back 


class MyGlossaryImportCallback
	attr_accessor :job,:total,:sofar,:stage
	def initialize(job)
		@job = job
		@total = 0
		@sofar = 0
	end
	def start(stage,count)
		printf("START %s,%s\n",stage,count)
		@total = count
		@stage = stage
		@job.update( stage: stage)
	end
	def sofar(stage,count)
		printf("SOFAR ---%s,%s,%s\n",stage,count,@total)
		@stage = stage
		@sofar = count
		if @total <=  0
			percent = 0
		else
			percent = (@sofar.to_i*100)/@total.to_i
		end
		printf("SOFAR %s,%s,%s,%s\n",stage,@sofar,@total,percent)
		msg = sprintf("%s of %s exported [%s]",@sofar,@total,percent.to_s+"%")
		@job.update( percent: percent)
		@job.update( message: msg)
		@job.update( stage: stage)
		printf("COUNT %s,%s,%s\n",stage,count,msg)
	end
	def done(stage)
		@stage = stage
		@job.update( percent: 100)
		@job.update( stage: stage)
		printf("DONE %s\n",stage)
	end
	def error(stage,msg)
		@stage = stage
		@job.update( percent: 100)
		@job.update( message: msg)
	end
	def finish()
		printf("FINISH\n")
		@job.update( status: 'done')
	end
end



