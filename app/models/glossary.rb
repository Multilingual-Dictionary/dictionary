class Glossary < ApplicationRecord

## Check if exists .. return true if exists
def record_exists()
	conn = ActiveRecord::Base.connection
	sql = " select id from glossaries where
		digest=#{conn.quote(self.digest)} limit 1 "
	res = conn.select_all(sql)
	if res.rows.empty?
		return false
	end
	return true
end

## add record  if not exists  return 1 if added otherwise 0
def add_if_not_exists()
	if record_exists()
		printf("EXISTS %s\n",self.digest)
		return 0
	end
	save()
	return 1
end

def count_records(dict_id)
	conn = ActiveRecord::Base.connection
	sql = " select count(id) as cnt from glossaries where
		dict_id=#{conn.quote(dict_id)} "
	res = conn.select_all(sql)
	if res.rows.empty?
		return 0
	end
	return res.rows[0][0]
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

def add_index(lang,key_words)
        key_words=remove_notes(key_words,"(",")")
        key_words=remove_notes(key_words,"{","}")
        key_words=remove_notes(key_words,"[","]")
	return if key_words==""
	printf("ADD KEY_WORDS (%s)(%s)\n",lang,key_words)
	key_words.gsub(/;/,",").split(',').each{|key|
		printf("KEY %s\n",key)
		key.strip!
		next if key==""
		next if key.length>250
		printf("ADD KEY (%s)(%s)\n",lang,key)
		idx = GlossaryIndex.new
		idx.dict_id = self.dict_id
		idx.lang = lang
		idx.key_words = key 
		idx.digest = self.digest
		idx.save
	}
end
def index_keys(cfg)
	add_index(cfg["key_words_lang"],self.key_words) if cfg["key_words_lang"]!=""
	add_index(cfg["primary_xlate_lang"],self.primary_xlate) if cfg["primary_xlate_lang"]!=""
	add_index(cfg["secondary_xlate_lang"],self.secondary_xlate) if cfg["secondary_xlate_lang"]!=""
end

def setup_record()
 	self.dict_id = '' if self.dict_id == nil 
 	self.key_words = '' if self.key_words == nil 
 	self.word_type = '' if self.word_type == nil 
 	self.category = '' if self.category == nil 
 	self.primary_xlate = '' if self.primary_xlate == nil 
 	self.secondary_xlate = '' if self.secondary_xlate == nil 
	self.key_words=self.key_words[0,250] if self.key_words.length>250
	self.word_type=self.word_type[0,79] if self.word_type.length>79
	self.category=self.category[0,79] if self.category.length>79

 	self.dict_id.strip!
 	self.key_words.strip!
 	self.word_type.strip!
 	self.category.strip!
 	self.primary_xlate.strip!
 	self.secondary_xlate.strip!

	md5 = Digest::MD5.new
	md5 << self.dict_id
	md5 << self.key_words
	md5 << self.word_type
	md5 << self.category
	md5 << self.primary_xlate
	md5 << self.secondary_xlate
	self.digest = md5.hexdigest
	printf("DIGEST[%s]\n",self.digest)
end
def params()
	return {
		"dict_id"  => self.dict_id,
		"key_words" => self.key_words,
		"word_type" => self.word_type,
		"category"  => self.category,
		"primary_xlate" => self.primary_xlate,
		"secondary_xlate" => self.secondary_xlate,
		"digest" => self.digest
		}
end

end
