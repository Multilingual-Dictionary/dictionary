#########################################################################################
##	UTIL
#########################################################################################

require "unicode_utils/casefold"
require 'whitesimilarity'

class HiliText 
	def initialize(cb)
		@cb = cb
		@enabled = true
		@hl_words = []
	end
	def add_word_to_hilite(words)
		@hl_words=words
	end
	def enable(enabled=true)
		@enabled=enabled
	end
	def to_hilite(word)
		max = 0.0
		@hl_words.each{|w|
			simi = WhiteSimilarity.similarity(w,word)
			max = simi if simi > max
		}
		return true if max > 0.75 
		return false
	end
	def hilite(txt,is_html=false)
		if @enabled == false
			if is_html
				return txt 
			else
				return CGI::escapeHTML(txt)
			end
		end

		hili_text=""
		n=txt.size
		i=0
		word_start=0
		word=""
		while i < n do
			c = txt[i,1]
			if c.match(/\p{^Alnum}/)
				## special char
				if word != ""
					if to_hilite(word)
						hili_text << @cb.hilite(word,is_html)
					else
						if is_html
							hili_text << word
						else
							hili_text << CGI::escapeHTML(word)
						end
					end
					word = ""
				end
				if is_html
					hili_text << c
				else
					hili_text << CGI::escapeHTML(c)
				end
			else
				## normal char
				word << c
			end
			i = i + 1
		end
		if word != ""
			if to_hilite(word)
				hili_text << @cb.hilite(word,is_html)
			else
				if is_html
					hili_text << word
				else
					hili_text << CGI::escapeHTML(word)
				end
			end
		end
		return hili_text
	end
end

class HiliUnderline 
	def hilite(word,is_html)
		if is_html
			return  "<u>"+word+"</u>"
		else
			return  "<u>"+CGI::escapeHTML(word)+"</u>"
		end
	end
end

class HiliTextUnderline < HiliText 
	def initialize()
		super(HiliUnderline.new)
	end
end
class HiliBold 
	def hilite(word)
		if is_html
			return  "<b>"+word+"</b>"
		else
			return  "<b>"+CGI::escapeHTML(word)+"</b>"
		end
	end
end

class HiliTextBold < HiliText 
	def initialize()
		super(HiliBold.new)
	end
end



