class DavkhktDictsController < ApplicationController
  before_action :set_davkhkt_dict, only: [:show, :edit, :update, :destroy]

  # GET /davkhkt_dicts
  # GET /davkhkt_dicts.json
  def index
	if params[:to_search]==nil or params[:to_search]==''
    		@davkhkt_dicts = DavkhktDict.all.limit(100)
	else
    		@davkhkt_dicts = DavkhktDict.where(key_words: params[:to_search])
	end
  end

  # GET /davkhkt_dicts/1
  # GET /davkhkt_dicts/1.json
  def show
  end

  # GET /davkhkt_dicts/new
  def new
    @davkhkt_dict = DavkhktDict.new
  end

  # GET /davkhkt_dicts/1/edit
  def edit
  end

  # POST /davkhkt_dicts
  # POST /davkhkt_dicts.json
  def create
    @davkhkt_dict = DavkhktDict.new(davkhkt_dict_params)

    respond_to do |format|
      if @davkhkt_dict.save
        format.html { redirect_to @davkhkt_dict, notice: 'Davkhkt dict was successfully created.' }
        format.json { render :show, status: :created, location: @davkhkt_dict }
      else
        format.html { render :new }
        format.json { render json: @davkhkt_dict.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /davkhkt_dicts/1
  # PATCH/PUT /davkhkt_dicts/1.json
  def update
    respond_to do |format|
      if @davkhkt_dict.update(davkhkt_dict_params)
        format.html { redirect_to @davkhkt_dict, notice: 'Davkhkt dict was successfully updated.' }
        format.json { render :show, status: :ok, location: @davkhkt_dict }
      else
        format.html { render :edit }
        format.json { render json: @davkhkt_dict.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /davkhkt_dicts/1
  # DELETE /davkhkt_dicts/1.json
  def destroy
    @davkhkt_dict.destroy
    respond_to do |format|
      format.html { redirect_to davkhkt_dicts_url, notice: 'Davkhkt dict was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_davkhkt_dict
      @davkhkt_dict = DavkhktDict.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def davkhkt_dict_params
      params.require(:davkhkt_dict).permit(:key_words, :type, :category, :english, :viet)
    end
end
