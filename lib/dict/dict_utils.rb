#########################################################################################
##	UTIL
#########################################################################################

require "unicode_utils/casefold"
require 'whitesimilarity'

class HiliText 
	def initialize(cb)
		@cb = cb
		@hl_words = []
	end
	def add_word_to_hilite(words)
		@hl_words=words
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
	def hilite(txt)
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
						hili_text << @cb.hilite(word)
					else
						hili_text << CGI::escapeHTML(word)
					end
					word = ""
				end
				hili_text << CGI::escapeHTML(c)
			else
				## normal char
				word << c
			end
			i = i + 1
		end
		if word != ""
			if to_hilite(word)
				hili_text << @cb.hilite(word)
			else
				hili_text << CGI::escapeHTML(word)
			end
		end
		return hili_text
	end
end

