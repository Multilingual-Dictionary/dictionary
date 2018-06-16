class CreateGlossaries < ActiveRecord::Migration[5.1]
  def change
    create_table :glossaries do |t|
      t.string :dict_id
      t.string :key_words
      t.string :word_type
      t.string :category
      t.text :primary_xlate
      t.text :secondary_xlate

      t.timestamps
    end
  end
end
