
require './lib/dict/glossary_export'

class ExportGlossaryJob < ApplicationJob
	queue_as :urgent

	def perform(id,export_params,notes)
	
		
		## start job now
		start(id,"export_glossary")
		@job.update( status: "in_progress")
		@job.update( stage: "exporting")
		
		## use sql
        db_config= YAML::load(File.open('config/database.yml'))
		
		## file where we store exported data
		data_file=DataFile.new
		data_file.filename = data_file.generate_filename("glossary","csv")
		data_file.job_id=id
		case export_params[:mode]
		when "export"
			tmp = export_params[:dict_id]
		else
			tmp=export_params[:dict_list]
			if tmp.length > 100
				tmp= tmp[0,100] + "__"
			end
			tmp = tmp + "." + export_params[:src_lang] + "." + export_params[:tgt_lang]
		end
		
		data_file.name="exp."+tmp
		data_file.data_type="exported.glossary"
		data_file.notes=notes
		data_file.save
		
		##  now call export class , this will call us back!
	
		@file = File.new(data_file.filename,"w")
		callback= MyGlossaryExportCallback.new(@job,@file)
        
		exp = GlossaryExport.new(
                      {
                        "host" => "localhost",
                        "username" => db_config[Rails.env]["username"],
                        "password" =>db_config[Rails.env]["password"],
                        "database" =>db_config[Rails.env]["database"]
                      },
                      callback)
					  
		case export_params[:mode]
		when "export"
			exp.export_glossary(export_params[:dict_id])
		else
			exp.export_terms(
					export_params[:src_lang],
					export_params[:tgt_lang],
					export_params[:dict_list])
		end				
		@file.close
	
	end

end

### Call back 

class MyGlossaryExportCallback
	attr_accessor :job,:total,:sofar,:stage,:file
	def initialize(job,file)
		@job = job
		@file = file
		@total = 0
		@sofar = 0
	end
	def start(stage,count)
		printf("START %s,%s\n",stage,count)
		@total = count
		@stage = stage
	end
	def write(data)
		@file.write(data)
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
		printf("COUNT %s,%s,%s\n",stage,count,msg)
	end
	def done(stage)
		@stage = stage
		@job.update( percent: 100)
		printf("DONE %s\n",stage)
	end
	def finish()
		printf("FINISH\n")
		@job.update( status: 'done')
	end
	def error(stage,msg)
		printf("error %s,%s\n",stage,msg)
        @job.update(status: 'error')
		@job.update(message: msg)
    end

end


