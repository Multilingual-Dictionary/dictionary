require 'tempfile'
require 'iconv'
require 'roo'
require 'roo-xls'
require 'json'

class GlossariesController < ApplicationController
  before_action :set_glossary, only: [:show, :edit, :update, :destroy]

  #
  # First Init , return error string or nil
  #
  def init_var
	@all_glossaries_configs = []
	@dict_id = params[:dict_id]
	DictConfig.all().each {|d|
		if d.protocol=='glossary' 
			@all_glossaries_configs << d
			@dict_id = d['dict_sys_name'] if @dict_id == nil
		end
	}
	params[:dict_id] = @dict_id 
puts("ALL ")
puts(DictConfig.where(protocol: 'glossary').inspect())
    @key_lang  = "?"
    @prim_lang  = "?"
    @sec_lang  = "?"
    @dict_name  = "?"
    @dict_id  = nil
    @dict_config=nil
    if params[:dict_id]==nil
      return
    end
	
    @dict_config=DictConfig.find_by( dict_sys_name: params[:dict_id])
puts("dict_config"+@dict_config.inspect())
    if @dict_config==nil
      return
    end
puts("OK")
    begin
      @dict_ext_cfg = JSON.parse(@dict_config.cfg)
    rescue Exception => e
      return 
    end
    puts(@dict_config.inspect)
    @dict_name  = @dict_config.dict_name
    @key_lang  = @dict_ext_cfg['config']['key_words_lang']
    @prim_lang = @dict_ext_cfg['config']['primary_xlate_lang']
    @sec_lang  = @dict_ext_cfg['config']['secondary_xlate_lang']
    @dict_id= params[:dict_id]
    return 
  end

  # GET /glossaries
  # GET /glossaries.json
  def index
    @glossaries = []
    err = init_var()
    if(@dict_id!=nil)

		if params[:to_search] == nil or 
		   params[:to_search] == '' 
		   @glossaries = Glossary.where(
		   			  [ "dict_id = :dict_id ",
				{ dict_id: @dict_id } ] ).limit(100)
		else
		   @glossaries = Glossary.where(
			  [ "dict_id = :dict_id and key_words = :key_words ",
				{ dict_id: @dict_id , key_words: params[:to_search] } ] )
		end
	end
  end

  # GET /glossaries/1
  # GET /glossaries/1.json
  def show
  end

  # GET /glossaries/new
  def new
    @glossary = Glossary.new
  end

  # GET /glossaries/1/edit
  def edit
  end

  # POST /glossaries
  # POST /glossaries.json
  def create
    @glossary = Glossary.new(glossary_params)
    @glossary.setup_record()

    respond_to do |format|
      if @glossary.save
        format.html { redirect_to @glossary, notice: 'Glossary was successfully created.' }
        format.json { render :show, status: :created, location: @glossary }
      else
        format.html { render :new }
        format.json { render json: @glossary.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /glossaries/1
  # PATCH/PUT /glossaries/1.json
  def update
    respond_to do |format|
      puts(glossary_params)
      tmp = Glossary.new(glossary_params)
      tmp.setup_record()
      if @glossary.update(tmp.params())
      ##if @glossary.update(glossary_params)
        format.html { redirect_to @glossary, notice: 'Glossary was successfully updated.' }
        format.json { render :show, status: :ok, location: @glossary }
      else
        format.html { render :edit }
        format.json { render json: @glossary.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /glossaries/1
  # DELETE /glossaries/1.json
  def destroy
    @glossary.destroy
    respond_to do |format|
      format.html { redirect_to glossaries_url, notice: 'Glossary was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_glossary
      @glossary = Glossary.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def glossary_params
      params.require(:glossary).permit(:dict_id, :key_words, :word_type, :category, :primary_xlate, :secondary_xlate,:digest)
    end
end

