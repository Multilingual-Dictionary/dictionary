require "json"

class AdminPagesController < ApplicationController
  def glossary_export
	require_role("ADMIN")
	printf("PARAMS START %s\n",params.inspect())
  	params[:src_lang]='DE' if params[:src_lang] == nil
	params[:tgt_lang]='VI' if params[:tgt_lang] == nil
  	params[:job_id]='0' if params[:job_id] == nil
	params[:job_status]='' if params[:job_status] == nil
	params[:download_id]='' if params[:download_id] ==nil
	if params[:mode] == nil
		params[:mode]= "export"
	end
	get_all_glossaries_configs()
	@glossaries_options=[] 
	@all_glossaries_configs.each {|inf|
		@glossaries_options<< [ inf.dict_name , inf.dict_sys_name ]
	}
	@lang_codes=Dictionaries.new([]).lang_codes
	@mode_options=[]
	@mode_options << ["Xuất dữ liệu từ một tự điển" , "export"]
	@mode_options << ["Kết xuất dữ liệu từ nhiều tự điển (cho CAT)" , "export_cat"]
	
	@selected_dicts=Hash.new
	@dict_list=Hash.new
    @dictionaries=Dictionaries.new(
			DictConfig.where( "priority>0 and protocol='glossary' ").order(priority: :desc))
	@dictionaries.dict_infos.each{|n,inf|
		next if not inf["src_languages"].include?(params[:src_lang])
		if inf["tgt_languages"].include?(params[:tgt_lang]) or params[:ref_lang]=="ALL" 
			@dict_list[inf["dict_sys_name"]]=inf
		end		  
	}
	@dict_list.each{|n,inf|
		@selected_dicts[n]=1 if params["CHK"+inf["dict_sys_name"]] != nil
	}
	if params[:download_id]!= ""
		download_data()
	end
	case params[:commit]
	when "Xuất dữ liệu"
	   export_data()
	else
		case params[:job_result]
		when "done"
			@notice = "Hoàn tất"
			if params[:job_id]!="0"
				data_file = DataFile.find_by(job_id: params[:job_id])
				if data_file != nil 
					@download_file=data_file.filename
					params[:download_id]=params[:job_id]
					params[:job_id] = "0"
				end
			end
		when "error"
			warn("Xuất dữ liệu bị lỗi!")
		end
	end
	params[:job_result]=""
	days=1
	query = sprintf(
				"select d.* "+
				"from data_files as d "+
				"left join "+
				"  dict_jobs as j "+ 
				"  on d.job_id=j.id "+
				" where d.data_type='exported.glossary' and "+
				"       j.status='done' and "+
				"       d.created_at>date_sub(now(),interval %d day) "+
				
				" order by created_at desc ",
				days)
	@exported=[]
	res= DataFile.find_by_sql(query)
	res.each{|r|
		n= json_parse(r.notes)
		next if n==nil
		e = Hash.new
		e["notes"] = n["user_notes"]
		e["file"]  = File.basename(r.filename)
		e["dicts"]=[]
		n["dict_ids"].split(",").each{|id|
			e["dicts"]<<@dictionaries.dict_name(id)
		}
		e["file_id"]=r.id
		@exported << e
	}
	params[:download_id]=""			
  end
  
  def export_data()
	export_params=Hash.new
	export_params[:mode] = params[:mode]
	notes=Hash.new
	notes[:mode]=params[:mode]
	notes[:user_notes]=""
	notes[:user_notes]=params[:notes] if params[:notes]!=nil
	if params[:mode] == "export"
		export_params[:dict_id]=params[:dict_id]
		notes[:dict_ids]=params[:dict_id]
	else  ## export_cat
		if @selected_dicts.size==0
			warn("Chưa chọn tự điển nào!")
			return
		end
		to_export=""
		@selected_dicts.each{|d,v|
			to_export<< "," if to_export !=""
			to_export<< d
		}
		export_params[:src_lang]=params[:src_lang]
		export_params[:tgt_lang]=params[:tgt_lang]
		export_params[:dict_list]=to_export
		notes[:dict_ids]= to_export
	end
	params[:job_id]='0'
	params[:job_status]=''
	dict_job = DictJob.new()
	id = dict_job.create_new()
	ret=ExportGlossaryJob.perform_later(id,export_params,JSON.generate(notes))
	dict_job.update(job_id: ret.job_id)
	params[:job_id] = id
  end
  def download_data()
	file_id= params[:download_id]
	printf("DODOWNLOAD %s\n",file_id)
 	data_file = DataFile.find_by(id: file_id)
	if data_file != nil 
		printf("SEND FILE %s\n",data_file.filename)
		send_file data_file.filename
		params[:download_id]=''
	else
		printf("NIL DATA\n")
	end  
  end
end
