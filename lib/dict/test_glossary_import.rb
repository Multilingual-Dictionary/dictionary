require_relative "glossary_import.rb"

cb= GlossaryImportCallback.new
imp=GlossaryImport.new(
		{"host" =>"localhost",
		 "username" => "root", 
		 "password" => "letien1512", 
		 "database" => "dictionary_development"
		},
		cb)
printf("DO IMPORT\n")
exit(0)
imp.import(ARGV[0],
		{
		"dict_id"=>"TEST-1", 
		"key_words_lang"=>"DE", 
		"primary_xlate_lang"=>"VI", 
		"secondary_xlate_lang"=>"EN", 
		"key_words"=>"0", 
		"word_type"=>"1", 
		"category"=>"2", 
		"primary_xlate"=>"4", 
		"secondary_xlate"=>"3" 
		} )

