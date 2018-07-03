
require 'iconv'
require 'roo'
require 'roo-xls'
require 'json'

class ImportPageController < ApplicationController
  #
  # util , is_numeric ??
  #
  def is_numeric(txt)
    return txt.to_s.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil ? false : true
  end
  #
  # util create Glossary Data from excel record
  #
  def get_from_excel(r)
    rec= Glossary.new
    rec.key_words = r[@key_words.to_i].to_s
    if is_numeric(@word_type)
      rec.word_type= r[@word_type.to_i].to_s
    else
      rec.word_type= @word_type.to_s
    end
    if is_numeric(@category)
      rec.category = r[@category.to_i].to_s
    else
      rec.category = @category.to_s
    end
    rec.primary_xlate = r[@primary_xlate.to_i].to_s
    if is_numeric(@secondary_xlate)
      rec.secondary_xlate   = r[@secondary_xlate.to_i].to_s
    else
      rec.secondary_xlate     = @secondary_xlate.to_s
    end
    return rec
  end
  
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

    @key_words  = params['key_words']
    if @key_words == nil
      ## get default
puts("GET FROM JSON")
      @key_words  = @dict_ext_cfg['config']['import_column']['key_words']
      @word_type  = @dict_ext_cfg['config']['import_column']['word_type']
      @category  = @dict_ext_cfg['config']['import_column']['category']
      @primary_xlate  = @dict_ext_cfg['config']['import_column']['primary_xlate']
      @secondary_xlate  = @dict_ext_cfg['config']['import_column']['secondary_xlate']
      if @key_words==nil or
         @word_type==nil or
         @category==nil or
         @primary_xlate==nil or
         @secondary_xlate==nil 
         return "BAD CONFIG DATA"
      end
    else
puts("GET FROM pARAMS")
puts(params.inspect())
      @word_type  = params['word_type']
      @category  = params['category']
      @primary_xlate  = params['primary_xlate']
      @secondary_xlate =  params['secondary_xlate']
    end
    puts("SECOND " + @secondary_xlate.to_s)
    
    return ""
  end
  #
  # CANCEL
  #
  def cancel_glossary_file()
    puts("CANCEL NOW")
    File::unlink(params[:tmp_file_name])
  end
  #
  # IMPORT Glossary
  #
  def import_glossary_file()
    puts("IMPORT NOW")
    begin
      workbook = Roo::Excel.new(params[:tmp_file_name])
      File::unlink(params[:tmp_file_name])
      ### OK we have data !
      sheet= workbook.sheet(0)
      sheet.each {|r|
		record= get_from_excel(r)
		record.dict_id = @dict_id
		record.add_if_not_exists()
      }
    rescue Exception => e
        puts e.message
    end
  end
  #
  # READ Glossary
  #
  def read_glossary_file(file)
    records = []
    begin
      tmp_name = "/tmp/"+file.original_filename
      tmp_file = File.new(tmp_name,"wb")
      tmp_file.write(file.read)
      tmp_file.close()
      workbook = Roo::Excel.new(tmp_name)
      sheet= workbook.sheet(0)
      i = 0
      @tmp_file_name = tmp_name
      sheet.each {|r|
		if i == 4
			break
		end
		i = i + 1
		rec = get_from_excel(r)
		records <<  get_from_excel(r)
      }
    rescue Exception => e
        puts e.message
        return []
    end
    return records
  end

  ##
  ## ACTION : IMPORT-GLOASSARY
  ##

  def import_glossary
    err = init_var()
    if err != ""
	   puts(err)
       return
    end
    puts(params.inspect())
    @records = []
    if params[:commit]!=nil
      case params[:commit].upcase
      when "READ"
        @records = read_glossary_file(params[:import_file])
	puts(@records.inspect())
      when "IMPORT"
        import_glossary_file()
      when "CANCEL"
        cancel_glossary_file()
      else
      end
    else
    end
  end

end

