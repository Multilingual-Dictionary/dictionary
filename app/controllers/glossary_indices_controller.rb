class GlossaryIndicesController < ApplicationController
  before_action :set_glossary_index, only: [:show, :edit, :update, :destroy]

  # GET /glossary_indices
  # GET /glossary_indices.json
  def index
    @glossary_indices = GlossaryIndex.all
  end

  # GET /glossary_indices/1
  # GET /glossary_indices/1.json
  def show
  end

  # GET /glossary_indices/new
  def new
    @glossary_index = GlossaryIndex.new
  end

  # GET /glossary_indices/1/edit
  def edit
  end

  # POST /glossary_indices
  # POST /glossary_indices.json
  def create
    @glossary_index = GlossaryIndex.new(glossary_index_params)

    respond_to do |format|
      if @glossary_index.save
        format.html { redirect_to @glossary_index, notice: 'Glossary index was successfully created.' }
        format.json { render :show, status: :created, location: @glossary_index }
      else
        format.html { render :new }
        format.json { render json: @glossary_index.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /glossary_indices/1
  # PATCH/PUT /glossary_indices/1.json
  def update
    respond_to do |format|
      if @glossary_index.update(glossary_index_params)
        format.html { redirect_to @glossary_index, notice: 'Glossary index was successfully updated.' }
        format.json { render :show, status: :ok, location: @glossary_index }
      else
        format.html { render :edit }
        format.json { render json: @glossary_index.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /glossary_indices/1
  # DELETE /glossary_indices/1.json
  def destroy
    @glossary_index.destroy
    respond_to do |format|
      format.html { redirect_to glossary_indices_url, notice: 'Glossary index was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_glossary_index
      @glossary_index = GlossaryIndex.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def glossary_index_params
      params.require(:glossary_index).permit(:dict_id, :lang, :key_words, :digest)
    end
end
