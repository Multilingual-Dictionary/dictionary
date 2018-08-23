class ExportGlossaryController < ApplicationController

  def export
  
  	params[:src_lang]='DE' if params[:src_lang] == nil
	params[:tgt_lang]='VI' if params[:tgt_lang] == nil
	params[:job_id]='0' if params[:job_id] == nil
	params[:job_status]='' if params[:job_status] == nil
    where = "priority>0 and protocol='glossary' "
    @dictionaries=Dictionaries.new(DictConfig.where(where).order(priority: :desc))
	
	do_export= false
	do_download= false
	case params[:commit]
	when "Kết xuất"
	   do_export= true
	when "Tải về"
	   do_download = true
	else
	   ## 
	end
	@selected_dicts=Hash.new
	@dict_list=Hash.new
	@dictionaries.dict_infos.each{|n,inf|
		next if not inf["src_languages"].include?(params[:src_lang])
		if inf["tgt_languages"].include?(params[:tgt_lang]) or params[:ref_lang]=="ALL" 
			@dict_list[inf["dict_sys_name"]]=inf
		end		  
	}
	@dict_list.each{|n,inf|
		@selected_dicts[n]=1 if params["CHK"+inf["dict_sys_name"]] != nil
	}
	printf("SELECTED DICTS %s\n",@selected_dicts.inspect())
	if do_download and params[:job_id] != '0' and params[:job_status]=='done'
		data_file = DataFile.find_by(job_id: params[:job_id])
		if data_file != nil 
			printf("SEND FILE %s\n",data_file.filename)
			send_file data_file.filename
			params[:job_id]='0'
			params[:job_status]=''
		end  
	end
    if @selected_dicts.length>0 and do_export
		to_export=""
		@selected_dicts.each{|d,v|
			to_export<< "," if to_export !=""
			to_export<< d
		}
	   printf("DO-EXPORT\n")
	   params[:job_id]='0'
	   params[:job_status]=''
       dict_job = DictJob.new()
       id = dict_job.create_new()
       ret = ExportGlossaryJob.perform_later(id,params[:src_lang],params[:tgt_lang],to_export)
	   dict_job.update(job_id: ret.job_id)
       params[:job_id] = id
    end
  end
end
