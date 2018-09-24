require "google/cloud/translate"
require_relative 'dict_service'

class GoogleDictService < DictService 
  def initialize(cfg=nil)
    @cfg = cfg
    printf("GOOGLE %s\n",@cfg.inspect())
    @engine = Google::Cloud::Translate.new(key: "AIzaSyDVBM9yohnLlhQ8TvwOmEo7FUudFQQxFgM")
    ##@engine = Google::Cloud::Translate.new(key: @cfg["ext_cfg"]["api_key"])
  end
  ##
  ##  LOOKUP ( to_search .. )
  ##
  def lookup(to_search,dict_id=nil)
    lookup_init()
    from_lang=""
    if @src_lang!="ALL"
       from_lang=@src_lang
    end
    cnt = 0
    xlated_word = Hash.new
    infos=Hash.new
    k = ""
    if @tgt_lang=="ALL"
       tgt_lang="EN,VI,DE,FR"
    else
       tgt_lang=@tgt_lang
    end
    txt=[]
    tgt_lang.split(",").each{|to_lang|
       printf("%s FROM %s TO %s\n",to_search,from_lang,to_lang)
       to_lang.strip
       next if to_lang==""
       next if to_lang == from_lang
       begin
          trans = @engine.translate(to_search,from: from_lang  ,to: to_lang)
	  printf("OK %s\n",trans.inspect())
       rescue 
	  printf("RESCUE\n")
          trans = nil
       end
       next if trans == nil
       begin
       	trans_lang = detect_language(trans.text)
       rescue
    	return []
       end

       next if to_lang != trans_lang
       next if trans.origin.upcase==trans.text.upcase
       txt << "["+to_lang.upcase+"] "+ trans.text
       xlated_word[to_lang]=[trans.text]
       infos[:key_lang]=trans.from
       k = trans.origin
       cnt += 1
    }
    return [] if cnt==0
    infos[:key_words]=to_search
    infos[:xlated_word]=xlated_word
    add_entry(@cfg["dict_sys_name"],k,txt,infos)
    return result()
  end
  def detect_language(to_search)
    translation = @engine.detect(to_search)
    if translation != nil and translation.confidence>0.5
       return translation.language.to_s.upcase
    end
    return ""
  end
end 

##google = GoogleDictService.new({"apikey"=>"AIzaSyDVBM9yohnLlhQ8TvwOmEo7FUudFQQxFgM","dict_sys_name"=>google})
##google.set_languages("EN","DE,VI,FR")
##
##res = google.lookup(ARGV[0])
#res = google.detect_language(ARGV[0])
##printf("RES %s\n",res.inspect())







