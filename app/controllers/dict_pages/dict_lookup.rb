require "./lib/dict/dict_utils"

class DictPagesController < ApplicationController

def debug(s)
	##File.write("./debug.txt",s,mode:"a")
end

def dict_lookup
	### SET DEFAUL PARAMS 

	params[:src_lang]='DE' if params[:src_lang] == nil
	params[:tgt_lang]='VI' if params[:tgt_lang] == nil
	params[:ref_lang]='ALL' if params[:ref_lang] == nil
	params[:to_search]='' if params[:to_search] == nil
	params[:search_mode]='search_contain' if params[:search_mode] == nil
	if params[:to_search].size > 60
		params[:to_search]=params[:to_search][0,60]
	end

	@cur_mode="lookup"
	if params[:lang_changed] == nil or  params[:lang_changed] == "1"
	    @cur_mode=""
	end
	
	### DOMAINS
if false
	### IGNORE THIS FOR NOW
	@domain_list={
		"GENERAL" => "Tổng quát",
		"NAT-SCI-TECH" => "Khoa học tự nhiên-kỹ thuật",
		"SOC-SCI" => "Khoa học xã hội-nhân văn"
	}
	domains=[]
	@domain_list.each{|domain,domain_name|
		chk_name="CHK_"+domain
		##printf("[%s][%s]\n",chk_name,params["CHK_"+domain])
		if params["CHK_"+domain] != nil
			domains << domain
			##printf("ADD [%s]\n",domain)
		end
	}
	if domains.size==0
		params["CHK_NAT-SCI-TECH"]="ON"
		domains << "NAT-SCI-TECH"
	end
else
	domains= ["GENERAL","NAT-SCI-TECH","SOC-SCI"] 
end

	
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
		##
		## user want to search de->de , en->en , vi->vi !
		##
		user_want_explanation= true
	end
	##debug(sprintf("RESULT %s\n",@result.inspect()))
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

  def build_summary_for_language(trans,dict_results,lang,summary,xlate_count=nil)

	summary["summary_for_lang"][lang]=Hash.new
	summary["summary_for_lang"][lang]["translated"]=Hash.new
	summary["summary_for_lang"][lang]["examples"]=Hash.new

	if trans[lang]!=nil
		trans[lang].each{|x|
			key = x["key"].downcase
			if lang==params[:src_lang] and
		   		(UnicodeUtils.casefold(x["key"]).gsub(/\p{^Alnum}/,"")==
		    		UnicodeUtils.casefold(x["xlate"]).gsub(/\p{^Alnum}/,""))
		   	next
			end
			key = x["key"].downcase
			if summary["summary_for_lang"][lang]["translated"][key]==nil
				summary["summary_for_lang"][lang]["translated"][key]=[]
			end
		
			summary["summary_for_lang"][lang]["translated"][key]<<
				{"xlate"=>x["xlate"],"dict"=>x["dict"],"score"=>x["score"]}
			if  xlate_count != nil 
				x["dict"].each{|d|
					xlate_count[d] += 1 
				}
			end
		}
	end
	###
	return if dict_results==nil
	hili=HiliTextUnderline.new()
	hili.add_word_to_hilite(params[:to_search].split(" "))
	dict_results.each{|r|
		r[:entries].each{|e|
			if e[:infos][:examples] != nil
				e[:infos][:examples].each{|ex|
					if ex[lang] != nil and ex[params[:src_lang]] != nil
						if summary["summary_for_lang"][lang]["examples"][r[:dict_name]]==nil
							summary["summary_for_lang"][lang]["examples"][r[:dict_name]]=[]
						end
						summary["summary_for_lang"][lang]["examples"][r[:dict_name]]<<
							{ 
							      :ex_src  => hili.hilite(ex[params[:src_lang]]),
							      :ex_tgt  => hili.hilite(ex[lang])
							}
					end
				}
			end
		}
	}
  end
  def build_summary(result,xlate_count)
	summary=Hash.new
	summary["message"]=""
	summary["summary_for_lang"]=Hash.new
	if result.length==0
		summary["message"]="NOT FOUND"
		return summary
	end
	trans =  @dictionaries.get_translated_words(result)

  	build_summary_for_language(trans,result,params[:tgt_lang],summary,xlate_count)
	if params[:ref_lang]=="ALL" 
		@dictionaries.lang_codes.each{|lang,lang_txt|
			next if lang==params[:tgt_lang]
			build_summary_for_language(trans,nil,lang,summary)
		}
	else
		params[:ref_lang].split(",").each{|lang|
			next if lang==params[:tgt_lang]
			build_summary_for_language(trans,nil,lang,summary)
		}
	end
	return summary
  end
end
