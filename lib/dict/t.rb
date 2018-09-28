require 'optparse'

	OptionParser.new do |opts|
		opts.on("-f") do |v|
			printf("FILE %s\n",v)
		end
	end
