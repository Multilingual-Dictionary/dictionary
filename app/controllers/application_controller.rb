class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  def initialize
    super
    @languages = {"EN"=>"Tiếng Anh","VI"=>"Tiếng Việt","DE"=>"Tiếng Đức" }
  end
  def hello
    render html: "hello, world!"
  end
end
