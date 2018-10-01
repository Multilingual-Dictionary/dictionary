class DictPagesController < ApplicationController

def dict_lookup
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
	
	### DOMAINS
	
	@domain_list={
		"GENERAL" => "Tổng quát",
		"NAT-SCI-TECH" => "Khoa học tự nhiên-kỹ thuật",
		"SOC-SCI" => "Khoa học xã hội-nhân văn"
	}
	domains=[]
	@domain_list.each{|domain,domain_name|
		chk_name="CHK_"+domain
		printf("[%s][%s]\n",chk_name,params["CHK_"+domain])
		if params["CHK_"+domain] != nil
			domains << domain
			printf("ADD [%s]\n",domain)
		end
	}
	if domains.size==0
		params["CHK_NAT-SCI"]="ON"
		domains << "NAT-SCI"
	end

	printf("domains %s\n",domains.inspect())
	
	### SEARCH-OPTIONS
	
	@search_opts = [ ['Tìm từ chính xác','search_exact'],
				     ['Tìm mục có chứa từ','search_contain'] ]
					 

	@dictionaries=Dictionaries.new(DictConfig.where("priority>0").order(priority: :desc))
	@key_words = []
	@key_words_list = []
	@result = []
	@sorted_results=Hash.new
	
	if params[:commit]=="Tìm từ khóa" and params[:search_key] != "" 
	  params[:search_mode] = "search_exact" 
	  params[:to_search] = params[:search_key] 
	end
	
	@dictionaries.set_search_mode(params[:search_mode])
	@dictionaries.set_search_key(params[:to_search])

	#### LOOKUP NOW!!!
	@result = @dictionaries.lookup_by_domains(
		params[:to_search],
		params[:src_lang],
		params[:tgt_lang].dup,
		params[:ref_lang],
		domains)

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
