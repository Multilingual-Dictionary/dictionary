require './app/helpers/dictionaries'

class DictPagesController < ApplicationController

  def home
  end

  def help
	puts(params.inspect())
  end

  def about
  end

  def admin
  end

  
def dict_lookup
	@dictionaries=Dictionaries.new(DictConfig.where("priority>0").order(priority: :desc))
	@key_words = []
	@key_words_list = []
	params[:cur_mode]='setup' if params[:cur_mode] == nil
	params[:src_lang]='DE' if params[:src_lang] == nil
	params[:tgt_lang]='VI' if params[:tgt_lang] == nil
	params[:ref_lang]='ALL' if params[:ref_lang] == nil
	params[:to_search]='' if params[:to_search] == nil
	params[:search_mode]='search_exact' if params[:search_mode] == nil
	if params[:show_select_dicts] != nil
	   @show_select_dicts = true
	else
	   @show_select_dicts = false
	end
	
	@cur_mode=""
	case params[:commit]
	when "Tìm kiếm"
	   @cur_mode='lookup'
	when "Tìm từ khóa"
	   @cur_mode='lookup' 
	end
	
	@dict_list=Hash.new
	@dictionaries.dict_infos.each{|n,inf|
	   printf("%s INFO %s,%s\n",n,inf["src_languages"].inspect(),inf["tgt_languages"].inspect())
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
	printf("SELECTED DICTS %s\n",@selected_dicts.inspect())
	return if @cur_mode!='lookup'
	use_dicts=""
	@selected_dicts.each{|name,v|
	   use_dicts << "," if use_dicts != ""
	   use_dicts << name
	}
	return if use_dicts==""
	if params[:commit]=="Tìm từ khóa" and params[:search_key] != "" 
	  params[:search_mode] = "search_exact" 
	  params[:to_search] = params[:search_key] 
	end
	@dictionaries.set_search_mode(params[:search_mode])
	@dictionaries.set_search_key(params[:to_search])
	@result = @dictionaries.lookup_dictionaries(
		params[:to_search],
		params[:src_lang],
		params[:tgt_lang],
		params[:ref_lang],
		use_dicts)
	printf("RESULT %s\n",@result.inspect())
	@key_words_list =  @dictionaries.get_key_words(@result)
  end
end
