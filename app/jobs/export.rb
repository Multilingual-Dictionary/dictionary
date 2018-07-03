# app/jobs/export.rb
class ExportJob < ProgressJob::Base
  def initialize(glossaries,progress_max)
    super progress_max: progress_max
    @max = progress_max
    @glossaries = glossaries
  end

  def perform()
	puts("PERFORM")
	puts(@max)
	puts(@glossaries)
  end
  def abc_perform
    update_stage('Exporting glossaries')
    puts("PERFORM")
    puts(@max)
    puts(@glossaries)
    i = 0
    100.times do
        puts(@max)
        puts(@glossaries)
	puts ("--" + i.to_s)
    end
##      @glossaries.each do |glossary|
##        csv << glossary.to_csv
##        update_progress
##      end
##    end
##   File.open('path/to/export.csv', 'w') { |f| f.write(csv_string) }
  end
end
