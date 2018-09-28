require_relative "glossary_import.rb"
cb= GlossaryImportCallback.new
imp=GlossaryImport.new(
		{"host" =>"localhost",
		 "username" => "root", 
		 "password" => "letien1512", 
		 "database" => "dictionary_development"
		},
		cb)
para = Hash.new 
para["dict_id"]=ARGV[1]
imp.import(ARGV[0], para)
