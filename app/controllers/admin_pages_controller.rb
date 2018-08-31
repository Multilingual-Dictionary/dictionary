require_relative "admin/config_dicts_controller"
require_relative "admin/config_dict_controller"
require_relative "admin/glossaries_controller"

class AdminPagesController < ApplicationController
  def admin_home
  end
  def config_user
  end
  def import_dict
	puts("IMPORT DICT")
	puts(params.inspect())
  end
end


