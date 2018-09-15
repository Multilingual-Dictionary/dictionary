require './app/helpers/dictionaries'
require './lib/dict/glossary_export'

class DictPagesController < ApplicationController

  def home
  end

  def help
	printf("HELP %s\n",params.inspect())
  end

  def about
  end

  def admin
  end

  
def dict_lookup

	@search_opts = [ ['Tìm từ chính xác','search_exact'],
				   ['Tìm mục có chứa từ','search_contain'] ]
	@dictionaries=Dictionaries.new(DictConfig.where("priority>0").order(priority: :desc))
	@key_words = []
	@key_words_list = []
	@result = []
	

	params[:src_lang]='DE' if params[:src_lang] == nil
	params[:tgt_lang]='VI' if params[:tgt_lang] == nil
	params[:ref_lang]='ALL' if params[:ref_lang] == nil
	params[:to_search]='' if params[:to_search] == nil
	params[:search_mode]='search_exact' if params[:search_mode] == nil

	
	@cur_mode="lookup"
	if params[:lang_changed] == nil or  params[:lang_changed] == "1"
	    @cur_mode=""
	end
	
	#case params[:commit]
	#when "Tìm kiếm"
	#   @cur_mode='lookup'
	#when "Tìm từ khóa"
	#   @cur_mode='lookup' 
	#end
	
	printf("CURMODE %s\n",@cur_mode)
	
	@dict_list=Hash.new
	@dictionaries.dict_infos.each{|n,inf|
	   next if not inf["src_languages"].include?(params[:src_lang])
	   if inf["tgt_languages"].include?(params[:tgt_lang]) or
	      params[:ref_lang]=="ALL" or 
          inf["tgt_languages"].include?(params[:ref_lang])         
   	     @dict_list[inf["dict_sys_name"]]=inf
       end		  
	}
	@selected_dicts=Hash.new
	@dict_list.each{|n,inf|
		if @cur_mode=='lookup'
	      @selected_dicts[n]=1 if params["CHK"+inf["dict_sys_name"]] != nil
		else
		  @selected_dicts[n]=1
	    end
	}
	printf("..%s,%s\n",@cur_mode,params[:to_search])
	return if @cur_mode!='lookup' or params[:to_search] ==""
	use_dicts=""
	@selected_dicts.each{|name,v|
	   use_dicts << "," if use_dicts != ""
	   use_dicts << name
	}
	printf("LOOKUP-- %s,%s\n",params[:to_search],use_dicts)
	return if use_dicts==""
	if params[:commit]=="Tìm từ khóa" and params[:search_key] != "" 
	  params[:search_mode] = "search_exact" 
	  params[:to_search] = params[:search_key] 
	end
	printf("LOOKUP %s,%s\n",params[:to_search],use_dicts)
	@dictionaries.set_search_mode(params[:search_mode])
	@dictionaries.set_search_key(params[:to_search])
	@result = @dictionaries.lookup_dictionaries(
		params[:to_search],
		params[:src_lang],
		params[:tgt_lang],
		params[:ref_lang],
		use_dicts)
	##printf("RESULT %s\n",@result.inspect())
	@summary=build_summary(@result)
	@key_words_list =  @dictionaries.get_key_words(@result)
  end

  def build_summary_for_language(trans,lang,summary)
	if trans[lang]==nil
		return
	end
	summary["translated"][lang]=Hash.new
	trans[lang].each{|x|
		key = x["key"].downcase
		if summary["translated"][lang][key]==nil
			summary["translated"][lang][key]=[]
		end
		summary["translated"][lang][key]<<
			{"xlate"=>x["xlate"],"dict"=>x["dict"]}
	}
  end
  def build_summary(result)
	summary=Hash.new
	summary["message"]=""
	summary["translated"]=Hash.new
	if result.length==0
		summary["message"]="NOT FOUND"
		return summary
	end
	trans =  @dictionaries.get_translated_words(result)
  	build_summary_for_language(trans,params[:tgt_lang],summary)
	if params[:ref_lang]=="ALL" 
		@dictionaries.lang_codes.each{|lang,lang_txt|
			next if lang==params[:tgt_lang]
			build_summary_for_language(trans,lang,summary)
		}
	else
		params[:ref_lang].split(",").each{|lang|
			next if lang==params[:tgt_lang]
			build_summary_for_language(trans,lang,summary)
		}
	end
	return summary
  end
end
