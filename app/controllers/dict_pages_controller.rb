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
	if params[:lookup_type] == nil
		params[:lookup_type]= 'lookup_dict' 
		@result= nil
	else
	
		if params[:commit]=="Tìm từ khóa" and params[:search_key] != "" 
			params[:search_mode] = "search_exact" 
			params[:to_search] = params[:search_key] 
		end
	
		@dictionaries.set_search_mode(params[:search_mode])
		@dictionaries.set_search_key(params[:to_search])
		case params[:lookup_type]
		when 'lookup_dict' 
			@result = @dictionaries.lookup_using_dict(
				params[:to_search],
				params[:selected_dict])
		when 'lookup_lang' 
			@result = @dictionaries.lookup_by_lang(
				params[:to_search],
				params[:src_lang],
				params[:tgt_lang])
		else
			@result = nil
		end
	end
        @key_words_list =  @dictionaries.get_key_words(@result)
  end

end
