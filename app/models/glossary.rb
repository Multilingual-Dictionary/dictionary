class Glossary < ApplicationRecord

## Check if exists .. return true if exists
def record_exists()
 	self.dict_id = '' if self.dict_id == nil 
 	self.key_words = '' if self.key_words == nil 
 	self.word_type = '' if self.word_type == nil 
 	self.category = '' if self.category == nil 
 	self.primary_xlate = '' if self.primary_xlate == nil 
 	self.secondary_xlate = '' if self.secondary_xlate == nil 
	conn = ActiveRecord::Base.connection
	sql = " select id from glossaries where
		dict_id=#{conn.quote(self.dict_id)} and
		key_words=#{conn.quote(self.key_words)} and
		word_type=#{conn.quote(self.word_type)} and
		category=#{conn.quote(self.category)} and
		primary_xlate=#{conn.quote(self.primary_xlate)} and
		secondary_xlate=#{conn.quote(self.secondary_xlate)} limit 1 "
	res = conn.select_all(sql)
	if res.rows.empty?
		return false
	end
	return true
end

## add record  if not exists  return 1 if added otherwise 0
def add_if_not_exists()
	if record_exists()
		return 0
	end
	save()
	return 1
end

end
