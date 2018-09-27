require './lib/dict/glossary_import'

class AdminPagesController < ApplicationController
  def glossary_import
	require_role("ADMIN")
	@dict_id=params[:dict_id]
	get_all_glossaries_configs()
	if params[:dict_id]==nil
		params[:dict_id]= @dict_id
	end
	printf("DO-IMPORT %s\n",params[:dict_id])
	@import_history=
		DictJob.find_by_sql(
		"SELECT * FROM dict_jobs where job_name='import_glossary' and "+
		"created_at>date_sub(now(),interval 1 day) "+
		"order by created_at desc")
	params[:job_id]='0' if params[:job_id] == nil
	params[:job_status]='' if params[:job_status] == nil
	params[:job_result]='' if params[:job_result] == nil
	@lang_codes=Dictionaries.new([]).lang_codes
	printf("LANGCODES %s\n",@lang_codes.inspect())
	get_dict_config(params[:dict_id])
	printf("DICTCFG %s\n",@dict_config.inspect())
	@lang_config=get_languages_config(@dict_config)
	if @lang_config==nil
		warn("Tự điển cấu hình chưa đúng")
		@lang_config=Hash.new
	end
	printf("LANGCFG %s\n",@lang_config.inspect())
	@glossaries_options=[] 
	@all_glossaries_configs.each {|inf|
		@glossaries_options<< [ inf.dict_name , inf.dict_sys_name ]
	}
	if params[:format]==nil or params[:format]!=@dict_id
		@lang_config.each{|t,v|
			params[:t]=v
		}
		params[:format]=@dict_id
	else
		@lang_config=Hash.new
		params.each{|t,v|
			tag=t.to_s
			if tag[0,1]=="#"
				@lang_config[t]=v
			end
		}
	end
	case params[:commit]
	when "Đọc file"
		## read & store temp.
		file = params[:imp_file]
		if file != nil 
			params[:tmp_file_name] = "./data_files/"+file.original_filename
			tmp_file = File.new(params[:tmp_file_name],"wb")
			tmp_file.write(file.read)
			tmp_file.close()
			imp=GlossaryImport.new()
			@file_data=imp.pre_read(params[:tmp_file_name],@lang_config)
			if @file_data != nil
				@fields= build_head(@file_data)
				params[:DATA_START]=@file_data["DATA_START"]
				@sample_datas=@file_data["SOME_DATAS"]
			else
				warn("Không thể đọc file")
				@sample_datas=nil
			end
		else
			params[:tmp_file_name]
			warn("Xin vui lòng chọn file!")
		end
	when "Bỏ qua"
		if params[:tmp_file_name] != nil
			File::unlink(params[:tmp_file_name])
		end
	when "Nhập file"
		run_import_job
	else
		case params[:job_result]
		when "done"
			@notice = "Nhập liệu hoàn tất"
		when "error"
			warn("Nhập liệu lỗi")
		end
	end
	
  end
  def run_import_job
	printf("DICT-ID %s\n",params["dict_id"])
	printf("DATA-STRT %s\n",params["DATA_START"])
	printf("FILE %s\n",params[:tmp_file_name])
	printf("LANG %s\n",@lang_config)
	@lang_config["DATA_START"]=params["DATA_START"]
	dict_job = DictJob.new()
	id = dict_job.create_new()
	ret = ImportGlossaryJob.perform_later(
			id,
			params["dict_id"],
			params[:tmp_file_name],
			@lang_config )
	dict_job.update(job_id: ret.job_id)
	params[:job_id] = id
	params[:job_status] = ""
	
  end
end
