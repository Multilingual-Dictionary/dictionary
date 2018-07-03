class ProgressBarsController < ApplicationController
  before_action :set_progress_bar, only: [:show, :edit, :update, :destroy]

  # GET /progress_bars
  # GET /progress_bars.json
  def index
    @progress_bars = ProgressBar.all
  end

  # GET /progress_bars/1
  # GET /progress_bars/1.json
  def show
	puts "ID IS"
	puts params[:id]
	render json: @progress_bar
  end

  # GET /progress_bars/new
  def new
    @progress_bar = ProgressBar.new
  end

  # GET /progress_bars/1/edit
  def edit
  end

  # POST /progress_bars
  # POST /progress_bars.json
  def create
    @progress_bar = ProgressBar.new(progress_bar_params)

    respond_to do |format|
      if @progress_bar.save
        format.html { redirect_to @progress_bar, notice: 'Progress bar was successfully created.' }
        format.json { render :show, status: :created, location: @progress_bar }
      else
        format.html { render :new }
        format.json { render json: @progress_bar.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /progress_bars/1
  # PATCH/PUT /progress_bars/1.json
  def update
    respond_to do |format|
      if @progress_bar.update(progress_bar_params)
        format.html { redirect_to @progress_bar, notice: 'Progress bar was successfully updated.' }
        format.json { render :show, status: :ok, location: @progress_bar }
      else
        format.html { render :edit }
        format.json { render json: @progress_bar.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /progress_bars/1
  # DELETE /progress_bars/1.json
  def destroy
    @progress_bar.destroy
    respond_to do |format|
      format.html { redirect_to progress_bars_url, notice: 'Progress bar was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_progress_bar
      @progress_bar = ProgressBar.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def progress_bar_params
      params.require(:progress_bar).permit(:message, :percent, :user_id)
    end
end
