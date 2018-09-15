require_relative "glossary_import.rb"

cb= GlossaryImportCallback.new
imp=GlossaryImport.new(
		{"host" =>"localhost",
		 "username" => "root", 
		 "password" => "letien1512", 
		 "database" => "dictionary_development"
		},
		cb)
imp=GlossaryImport.new()
fmt=imp.pre_read(ARGV[0],
       		{
                	"#TERM:DE"=>0,
                	"#CATEGORY:EN"=>1,
                	"#TERM:EN"=>2,
                	"#TERM:FR"=>3,
                	"DATA_START"=>0
        	})

printf("fmt %s\n",fmt.inspect())
