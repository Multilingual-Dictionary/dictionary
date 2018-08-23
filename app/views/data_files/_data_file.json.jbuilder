json.extract! data_file, :id, :name, :type, :notes, :filename, :job_id, :created_at, :updated_at
json.url data_file_url(data_file, format: :json)
