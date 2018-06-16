class AdminPagesController < ApplicationController
  def admin_home
  end
  def config_dict
  end
  def config_user
  end
  def import_dict
	puts("IMPORT DICT")
	puts(params.inspect())
  end
end
