class CreateProgressBars < ActiveRecord::Migration[5.1]
  def change
    create_table :progress_bars do |t|
      t.text :message
      t.integer :percent
      t.integer :user_id

      t.timestamps
    end
  end
end
