class ExportGlossaryController < ApplicationController
  def export_data(dictionaries,checked)
    puts("EXPORT DATA")
    puts(checked.inspect())
  end
  def export
    where = "priority>0 and protocol='glossary' "
    if params[:src_lang] != nil and
       params[:src_lang] != "ALL"
       where << "and lang='"+ params[:src_lang] + "'"
    end
    @dictionaries=DictConfig.where(where).order(priority: :desc)
    @checked = Hash.new
    @dictionaries.each{|d|
	@checked[d.dict_sys_name]=1 if params["CHK"+d.dict_sys_name] != nil
    }
    if @checked.length>0  and params[:commit]=="Kết xuất"
       ##export_data(@dictionaries,@checked)
       ##ExportJob.perform "abc", "def" ,"ijk"
      @job = Delayed::Job.enqueue ExportJob.new("test", 1000)
    end
  end
end
