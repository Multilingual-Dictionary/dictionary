require_relative 'rfc2229_dict_service'

dict= RFC2229DictService.new()
ARGV.each do |word|
	res = dict.lookup(word,'gcide')
	res.each {|r|
		puts(r.inspect)
	}
end
