require_relative "glossary_import.rb"

cb= GlossaryImportCallback.new
imp=GlossaryImport.new(
		{"host" =>"localhost",
		 "username" => "root", 
		 "password" => "letien1512", 
		 "database" => "dictionary_development"
		},
		cb)
imp.import(ARGV[1],
		{
		"dict_id"=>ARGV[0], 
		} )

