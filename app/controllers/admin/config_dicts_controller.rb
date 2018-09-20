class AdminPagesController < ApplicationController
def config_dicts
	require_role("ADMIN")
	printf("CFG-DICTS %s\n",params.inspect())
	if params[:dict_name] != nil and  params[:dict_name] != ""
		printf("---\n")
		@dict_configs = DictConfig.where(
			"dict_name like ?","%"+params[:dict_name]+"%").
				order(priority: :desc, dict_name: :asc) 
	else
		@dict_configs = DictConfig.order(priority: :desc, dict_name: :asc) 
    	end
  end
end
