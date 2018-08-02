class CreateGlossaryIndices < ActiveRecord::Migration[5.1]
  def change
    create_table :glossary_indices do |t|
      t.text :dict_id
      t.text :lang
      t.text :key_words
      t.text :digest
      t.timestamps
    end
  end
end
