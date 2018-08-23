class CreateDictJobs < ActiveRecord::Migration[5.1]
  def change
    create_table :dict_jobs do |t|
      t.string :job_id
      t.string :job_name
      t.text :in_data
      t.text :out_data
      t.string :stage
      t.string :percent
      t.string :status
      t.string :message
      t.string :notes

      t.timestamps
    end
  end
end
