
require 'tempfile'
require 'iconv'
require 'roo'
require 'roo-xls'
require 'json'

class ImportPageController < ApplicationController
  #
  # First Init , return error string or nil
  #
  def init_var
    @key_lang  = "?"
    @prim_lang  = "?"
    @sec_lang  = "?"
    @dict_name  = "?"
	@dict_id='?'
    @dict_config=nil
    if params[:dict_id]==nil
      return "BUG: DICT_ID NOT DEFINED!"
    end
	@dict_id=params[:dict_id]
    @dict_config=DictConfig.find_by( dict_sys_name: params[:dict_id])
    if @dict_config==nil
      return "ERR:DICT NOT CONFIGURATED!"
    end
    begin
      @dict_ext_cfg = JSON.parse(@dict_config.cfg)
    rescue Exception => e
      return "ERR:JSON:"+e
    end
    @dict_name  = @dict_config.dict_name
    @key_lang  = @dict_ext_cfg['config']['key_words_lang']
    @prim_lang = @dict_ext_cfg['config']['primary_xlate_lang']
    @sec_lang  = @dict_ext_cfg['config']['secondary_xlate_lang']
    return ""
  end
  #
  # IMPORT Glossary
  #
  def import_glossary_file(file)
    begin
      key_words  = @dict_ext_cfg['config']['import_column']['key_words']
      word_type  = @dict_ext_cfg['config']['import_column']['word_type']
      category  = @dict_ext_cfg['config']['import_column']['category']
      primary_xlate  = @dict_ext_cfg['config']['import_column']['primary_xlate']
      secondary_xlate  = @dict_ext_cfg['config']['import_column']['secondary_xlate']
      if key_words==nil or
         word_type==nil or
         category==nil or
         primary_xlate==nil or
         secondary_xlate==nil 
         return "BAD CONFIG DATA"
      end
      tmp_name = "/tmp/"+file.original_filename
      tmp_file = File.new(tmp_name,"wb")
      tmp_file.write(file.read)
      tmp_file.close()
      workbook = Roo::Excel.new(tmp_name)
      File::unlink(tmp_name)
      ### OK we have data !
      sheet= workbook.sheet(0)
      sheet.each {|r|
		record= Glossary.new
		record.dict_id = @dict_id
		record.key_words = r[key_words].to_s

      		case word_type.class.to_s
		when 'Integer'
			record.word_type     = r[word_type].to_s
		else
			record.word_type     = word_type.to_s
		end

      		case category.class.to_s
		when 'Integer'
			record.category     = r[category].to_s
		else
			record.category     = category.to_s
		end

		record.primary_xlate = r[primary_xlate].to_s

      		case secondary_xlate.class.to_s
		when 'Integer'
			record.secondary_xlate     = r[secondary_xlate].to_s
		else
			record.secondary_xlate     = secondary_xlate.to_s
		end

		record.add_if_not_exists()
      }
    rescue Exception => e
        puts e.message
    end
  end


  def import_glossary

    err = init_var()
    if err != ""
	   puts(err)
       return
    end
    import_glossary_file(params[:import_file])
  end

end

