class DavkhktDict < ApplicationRecord
def esc(a)
	return a
end
def record_exists()
 	self.key_words = '' if self.key_words == nil 
 	self.wtype = '' if self.wtype == nil 
 	self.category = '' if self.category == nil 
 	self.english = '' if self.english == nil 
 	self.viet = '' if self.viet == nil 
	conn = ActiveRecord::Base.connection
	sql = " select id from davkhkt_dicts where
		key_words=#{conn.quote(self.key_words)} and
		wtype=#{conn.quote(self.wtype)} and
		category=#{conn.quote(self.category)} and
		viet=#{conn.quote(self.viet)} and
		english=#{conn.quote(self.english)} limit 1 "
	res = conn.select_all(sql)
	if res.rows.empty?
		return false
	end
	return true
end

end
