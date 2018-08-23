class DataFile < ApplicationRecord
	def generate_filename(base_name,ext="")
		if ext != ""
			file_ext = "."+ext
		else
			file_ext = ""
		end
		return "./data_files/"+base_name+"."+DateTime.now.strftime("%Y-%m-%d-%H.%M.%S.%L")+file_ext
	end
end
