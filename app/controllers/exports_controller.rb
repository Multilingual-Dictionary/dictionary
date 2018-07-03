# app/controllers/exports_controller.rb
class ExportsController < ApplicationController
  def index
  end
  def export_glossaries
    @job = Delayed::Job.enqueue ExportJob.new("test", 1000)
  end
end
