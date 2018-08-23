class ApplicationJob < ActiveJob::Base
	attr_accessor :job,:job_id

def start(id,name)
	@job_id=id
	begin
		@job = DictJob.find(id)
	rescue
		@job = nil
		return self.job
	end
        @job.job_name=name
	@job.out_data=""
	@job.status="started"
	@job.percent=0
	@job.save
	return self.job
end


end
