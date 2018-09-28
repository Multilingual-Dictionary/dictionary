require './app/helpers/dictionaries'
require './lib/dict/glossary_export'
require_relative "dict_pages/dict_add"
require_relative "dict_pages/dict_lookup"

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

  def error
	warn(params[:error])
  end

end
