class CreateDictConfigs < ActiveRecord::Migration[5.1]
  def change
    create_table :dict_configs do |t|
      t.string :dict_sys_name
      t.text :dict_name
      t.string :lang
      t.string :xlate_lang
      t.text :desc
      t.string :protocol
      t.string :url
      t.string :syntax
      t.text :ext_infos

      t.timestamps
    end
  end
end
