class CreateDavkhktDicts < ActiveRecord::Migration[5.1]
  def change
    create_table :davkhkt_dicts do |t|
      t.string :key_words
      t.string :type
      t.string :category
      t.string :english
      t.string :viet

      t.timestamps
    end
  end
end
