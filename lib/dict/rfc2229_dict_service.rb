require_relative 'dict_service'
require_relative 'rfc2229'
require "getoptlong"

class RFC2229DictService < DictService 
	def initialize(cfg=nil)
		if(cfg==nil)
			cfg ={
				:host       => ENV[ "DICT_HOST" ]  || Dict::DEFAULT_HOST,
				:port       => ENV[ "DICT_PORT" ]  || Dict::DEFAULT_PORT,
				:strategy   => ENV[ "DICT_STRAT" ] || Dict::MATCH_DEFAULT}
		end
		@cfg = cfg
	end
	def lookup(to_search,dict_name=nil)
		lookup_init()
		if dict_name==nil
			dict_name =  ENV[ "DICT_DB" ]    || Dict::DB_ALL
		end
		begin
			DictClient.new( @cfg[ :host ], @cfg[ :port ] ).connect() do |dc|
				if (defs = dc.define( to_search, dict_name ) ).empty?
        				dc.disconnect()
					return result()
        			end 
				cur_res=nil
				defs.each do |wd|
  					name = "#{wd.database}-#{wd.name}"
					i = 0
					k = ''
					t = ''
       		         		wd.each {|line| 
						if i == 0
							k = line
						else
							t << line + "\n"
						end
						i += 1
					}
					add_entry(wd.database,k,t)
				end
				dc.disconnect()
			end ### do |dc|
    		rescue SocketError => e
			return result("Error connecting to server: #{e}")
		rescue DictError => e
			return result("Server error: #{e}")
    		rescue /WIN/i.match( RUBY_PLATFORM ) ? Errno::E10061 : Errno::ECONNREFUSED => e
			return result("Error connecting to server: #{e}")
    		end ## begin
		return result()
	end
end 
