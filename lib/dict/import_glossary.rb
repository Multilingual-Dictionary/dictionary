##
##	Import excel file -> dictionary
##
require_relative "glossary_import.rb"

host=	"localhost" if host==nil
username="root" if username==nil
password="letien1512" if password==nil
database="dictionary_development" if database==nil

puts host
puts username
puts password
puts database
puts ARGV[0]
puts ARGV[1]

cb= GlossaryImportCallback.new
imp=GlossaryImport.new(
		{"host" =>host,
		 "username" => username, 
		 "password" => password, 
		 "database" => database
		},
		cb)
para = Hash.new 
para["dict_id"]=ARGV[1]
imp.import(ARGV[0], para)
