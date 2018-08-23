json.extract! dict_job, :id, :job_id, :job_name, :in_data, :out_data, :stage, :percent, :status, :message, :notes, :created_at, :updated_at
json.url dict_job_url(dict_job, format: :json)
