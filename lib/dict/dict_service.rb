class DictResults 
	attr_accessor :error,:results
	def initialize(e=nil)
		@error=e;
		@results=Hash.new()
	end
	def resultOf(name)
	end
end
class DictService
	attr_accessor :res , :error
	def lookup_init()
		@res = Hash.new
		@error= nil
	end
	def result(err=nil)
		ret = []
		if(err!=nil)
			@error = err
			return  ret
		end
		@res.each_value {|r|
			
			ret << r
		}
		return ret
	end
	def add_entry( dict_name, key , text , infos=nil )
		if !@res.has_key?dict_name 
			@res [dict_name] = 
				{ :dict_name => dict_name ,
				  :entries   => [] }
		end
		txt=[]
		text.each{|t|
			txt << t.force_encoding(Encoding::UTF_8)
		}
		@res[dict_name][:entries] << 
			{ :key => key.force_encoding(Encoding::UTF_8),
			  :text=> txt,
			  :infos => infos}
	end
end
