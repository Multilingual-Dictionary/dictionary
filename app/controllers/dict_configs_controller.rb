class DictConfigsController < ApplicationController
  before_action :set_dict_config, only: [:show, :edit, :update, :destroy]

  # GET /dict_configs
  # GET /dict_configs.json
  def index
	printf("CFG %s\n",params.inspect())
    if params[:dict_name] != nil and  params[:dict_name] != ""
	printf("---\n")
       @dict_configs = DictConfig.where("dict_name like ?","%"+params[:dict_name]+"%").order(priority: :desc, dict_name: :asc) 
    else
       @dict_configs = DictConfig.order(priority: :desc, dict_name: :asc) 
    end
  end

  # GET /dict_configs/1
  # GET /dict_configs/1.json
  def show
  end

  # GET /dict_configs/new
  def new
    @dict_config = DictConfig.new
  end

  # GET /dict_configs/1/edit
  def edit
  end

  # POST /dict_configs
  # POST /dict_configs.json
  def create
    cfg_params= dict_config_params
    cfg_params[:dict_sys_name]=cfg_params[:dict_sys_name].strip()
    @dict_config = DictConfig.new(cfg_params)

    respond_to do |format|
      ok = 1
      if @dict_config.find_by_sys_name() != nil
        @dict_config.errors.add(:dict_sys_name, :invalid, message: "dict_sys_name already used!")
        ok = 0
      end
      if ok == 1 and @dict_config.save
        format.html { redirect_to @dict_config, notice: 'Dict config was successfully created.' }
        format.json { render :show, status: :created, location: @dict_config }
      else
        format.html { render :new }
        format.json { render json: @dict_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dict_configs/1
  # PATCH/PUT /dict_configs/1.json
  def update
    respond_to do |format|
      ok = 1
      cfg_params= dict_config_params
      cfg_params[:dict_sys_name]=cfg_params[:dict_sys_name].strip()
      rec=@dict_config.find_by_sys_name(cfg_params[:dict_sys_name])
      if rec != nil and rec.id != @dict_config.id 
        @dict_config.errors.add(:dict_sys_name, :invalid, message: "dict_sys_name already used!")
        ok = 0
      end
      if ok==1 and @dict_config.update(cfg_params)
        format.html { redirect_to @dict_config, notice: 'Dict config was successfully updated.' }
        format.json { render :show, status: :ok, location: @dict_config }
      else
        format.html { render :edit }
        format.json { render json: @dict_config.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dict_configs/1
  # DELETE /dict_configs/1.json
  def destroy
    @dict_config.destroy
    respond_to do |format|
      format.html { redirect_to dict_configs_url, notice: 'Dict config was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dict_config
      @dict_config = DictConfig.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dict_config_params
      params.require(:dict_config).permit(:dict_sys_name, :dict_name, :lang, :xlate_lang, :desc, :protocol, :url, :syntax, :ext_infos,:cfg,:priority,:dict_id)
    end
end
