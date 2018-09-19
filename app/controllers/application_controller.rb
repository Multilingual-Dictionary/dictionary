require 'csv'
require_relative '../jobs/export.rb'
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  def initialize
    super
    @languages = {"ALL"=>"Mặc định",
				  "VI"=>"Tiếng Việt",
				  "EN"=>"Tiếng Anh",
				  "DE"=>"Tiếng Đức",
				  "FR"=>"Tiếng Pháp"}
  end
  def warn(txt)
	@warning='' if @warn==nil
	@warning << txt if txt != nil
  end
end
