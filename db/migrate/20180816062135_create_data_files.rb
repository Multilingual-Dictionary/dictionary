class CreateDataFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :data_files do |t|
      t.string :name
      t.string :type
      t.string :notes
      t.string :filename
      t.string :job_id

      t.timestamps
    end
  end
end
