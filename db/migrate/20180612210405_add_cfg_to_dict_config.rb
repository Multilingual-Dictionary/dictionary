class AddCfgToDictConfig < ActiveRecord::Migration[5.1]
  def change
    add_column :dict_configs, :cfg, :text
  end
end
