require_relative "glossary_export.rb"

cb= GlossaryExportCallback.new
exp=GlossaryExport.new(
		{"host" =>"localhost",
		 "username" => "root", 
		 "password" => "letien1512", 
		 "database" => "dictionary_development"
		},
		cb)
#exp.export_terms(ARGV[0],ARGV[1],ARGV[2])
exp.export_glossary(ARGV[0])
