require_relative "admin/config_dicts_controller"
require_relative "admin/config_dict_controller"
require_relative "admin/glossaries_controller"
require_relative "admin/glossaries_import"
require_relative "admin/glossaries_export"

class AdminPagesController < ApplicationController

  before_action :require_login
 
  def admin_home
  end
  def config_user
  end
  def import_dict
	puts("IMPORT DICT")
	puts(params.inspect())
  end

  private

  def require_role(role)
	current_user
	if @current_user==nil
		redirect_to error_path(error: "Bạn chưa đang nhập!")
	else
		if role==""
			return
		end
		if @current_user.role==nil or
		   @current_user.role.index(role)==nil
			redirect_to error_path(error: sprintf("Bạn chưa có quyền : %s ",role))
		end
	end
  end

  def require_login
	require_role("")
  end

end


