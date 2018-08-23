require 'whitesimilarity'
class DictResultParser
	def initialize(name)
		@name=name;
	end
	def tokenize(txt)
     		return []  if txt == nil
     		return txt.gsub(/;/,",").split(',')
  	end
	def remove_notes(txt,open,close)
		is_in = false
		res = ""
		txt.each_char{|c|
			if c==open
				is_in = true
        			next
     			end
     			if c == close
        			is_in = false
        			next
     			end
     			if not is_in
        			res << c
     			end
   		}
   		return res
  	end
	def parse(results)
		printf("RESULTS\n")
		parsed_results=[]
		results.each{|result|
			parsed_result=Hash.new
			result.each{|h,v|
				parsed_result[h]=v
				printf(" : %s\n",h)
				if h.to_s == "entries"
					printf("entries %s\n",v.inspect())
					parsed_entries=[]
					v.each{|entry|
						entry.each{|hash,value|
							printf("HASH %s\n",hash)
						}
						printf("INFOS %s\n",entry[:infos])
						parsed_entries << entry
					}
					parsed_result[h]=parsed_entries
					
				end
			}
			parsed_results << parsed_result
		}
		return parsed_results
		results.each{|result|
			parsed_result=Hash.new
			parsed_result[:dict_name]=result[:dict_name]
			parsed_result[:entries]=[]
			result[:entries].each{|entry|
				parsed_entry=Hash.new
				parsed_entry[:key]= entry[:key].gsub('@','').strip
				parsed_entry[:text]= []
				entry[:text].each{|txt|
					#if txt[0] == "="
					#	printf("IGNORE %s\n",txt)
					#	next
					#end
					parsed_entry[:text]<< txt
					printf("RM[%s\n",remove_notes(txt,"{","}"))
				}
				parsed_result[:entries]<<parsed_entry
			}
			parsed_results << parsed_result
		}
		printf("PARSED %s\n",parsed_results.inspect())
		return results
	end
end
