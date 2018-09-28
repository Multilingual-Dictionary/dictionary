class DictPagesController < ApplicationController

def dict_lookup

	@search_opts = [ ['Tìm từ chính xác','search_exact'],
				   ['Tìm mục có chứa từ','search_contain'] ]
	@dictionaries=Dictionaries.new(DictConfig.where("priority>0").order(priority: :desc))
	@key_words = []
	@key_words_list = []
	@result = []
	@sorted_results=Hash.new
	
	### SET DEFAUL PARAMS 

	params[:src_lang]='DE' if params[:src_lang] == nil
	params[:tgt_lang]='VI' if params[:tgt_lang] == nil
	params[:ref_lang]='ALL' if params[:ref_lang] == nil
	params[:to_search]='' if params[:to_search] == nil
	params[:search_mode]='search_exact' if params[:search_mode] == nil


	@cur_mode="lookup"
	if params[:lang_changed] == nil or  params[:lang_changed] == "1"
	    @cur_mode=""
	end
	
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
	##printf("..%s,%s\n",@cur_mode,params[:to_search])
	return if @cur_mode!='lookup' or params[:to_search] ==""


	use_dicts=""
	@selected_dicts.each{|name,v|
	   use_dicts << "," if use_dicts != ""
	   use_dicts << name
	}
	##printf("LOOKUP-- %s,%s\n",params[:to_search],use_dicts)
	return if use_dicts==""
	if params[:commit]=="Tìm từ khóa" and params[:search_key] != "" 
	  params[:search_mode] = "search_exact" 
	  params[:to_search] = params[:search_key] 
	end
	##printf("LOOKUP %s,%s\n",params[:to_search],use_dicts)
	@dictionaries.set_search_mode(params[:search_mode])
	@dictionaries.set_search_key(params[:to_search])

	#### LOOKUP NOW!!!
	@result = @dictionaries.lookup_dictionaries(
		params[:to_search],
		params[:src_lang],
		params[:tgt_lang].dup,
		params[:ref_lang],
		use_dicts)

	#### SORT RESULTS 

	xlate_count=Hash.new
	user_want_explanation= false
	if params[:src_lang] ==params[:tgt_lang]
		user_want_explanation= true
	end
	@result.each{|r|
		cnt = 1
		lang_tag="["+params[:tgt_lang].upcase+"]"
		r[:entries].each{|e|
			e[:text].each{|txt|
				if txt.index(lang_tag) == 0
					cnt = cnt + 1
				end
			}
		}
		xlate_count[r[:dict_name]]=cnt
	}
	@summary=build_summary(@result,xlate_count)
	if user_want_explanation
		xlate_count.each{|dict,count|
  			if @dictionaries.has_explanation(dict)
				xlate_count[dict] = count * 100 
				##printf("DICT %s has explanation  %d\n",dict,count)
			end
		}
	end

	@sorted= xlate_count.sort_by{|dict,count| count}
	@sorted.reverse!
	@sorted.each{|d,v|
		@result.each{|r|
			if r[:dict_name] == d
				@sorted_results[d]= r
			end
		}
	}

	@key_words_list =  @dictionaries.get_key_words(@result)

  end

  def build_summary_for_language(trans,lang,summary,xlate_count=nil)
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
		if  xlate_count != nil 
			x["dict"].each{|d|
				xlate_count[d] += 1 
			}
		end
	}
  end
  def build_summary(result,xlate_count)
	summary=Hash.new
	summary["message"]=""
	summary["translated"]=Hash.new
	if result.length==0
		summary["message"]="NOT FOUND"
		return summary
	end
	trans =  @dictionaries.get_translated_words(result)
  	build_summary_for_language(trans,params[:tgt_lang],summary,xlate_count)
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
