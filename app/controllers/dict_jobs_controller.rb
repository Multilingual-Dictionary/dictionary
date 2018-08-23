class DictJobsController < ApplicationController
  before_action :set_dict_job, only: [:show, :edit, :update, :destroy]

  # GET /dict_jobs
  # GET /dict_jobs.json
  def index
    @dict_jobs = DictJob.all
  end

  # GET /dict_jobs/1
  # GET /dict_jobs/1.json
  def show
	puts "ID IS"
	puts params[:id]
	render json: @dict_job
  end
  def progress
	puts ( params )
	id = params[:id]
	begin 
 		@dict_job = DictJob.where(["id = ?", id]).select("id,status,percent,stage,job_name,message").first
	rescue
		@dict_job=nil
	end
	if @dict_job!= nil
		render json: @dict_job
		return
	end
	render json: {"id"=>params[:id],
                              "status"=>"not_exists"}
  end

  # GET /dict_jobs/new
  def new
    @dict_job = DictJob.new
  end

  # GET /dict_jobs/1/edit
  def edit
  end

  # POST /dict_jobs
  # POST /dict_jobs.json
  def create
    @dict_job = DictJob.new(dict_job_params)

    respond_to do |format|
      if @dict_job.save
        format.html { redirect_to @dict_job, notice: 'Dict job was successfully created.' }
        format.json { render :show, status: :created, location: @dict_job }
      else
        format.html { render :new }
        format.json { render json: @dict_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /dict_jobs/1
  # PATCH/PUT /dict_jobs/1.json
  def update
    respond_to do |format|
      if @dict_job.update(dict_job_params)
        format.html { redirect_to @dict_job, notice: 'Dict job was successfully updated.' }
        format.json { render :show, status: :ok, location: @dict_job }
      else
        format.html { render :edit }
        format.json { render json: @dict_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /dict_jobs/1
  # DELETE /dict_jobs/1.json
  def destroy
    @dict_job.destroy
    respond_to do |format|
      format.html { redirect_to dict_jobs_url, notice: 'Dict job was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dict_job
      @dict_job = DictJob.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def dict_job_params
      params.require(:dict_job).permit(:job_id, :job_name, :in_data, :out_data, :stage, :percent, :status, :message, :notes)
    end
end
