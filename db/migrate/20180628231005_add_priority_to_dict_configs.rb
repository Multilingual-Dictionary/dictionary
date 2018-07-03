class AddPriorityToDictConfigs < ActiveRecord::Migration[5.1]
  def change
    add_column :dict_configs, :priority, :int
  end
end
