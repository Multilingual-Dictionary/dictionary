class DictConfig < ApplicationRecord
   def find_by_sys_name(dict_sys_name=nil)
      dict_sys_name=self.dict_sys_name if dict_sys_name==nil
      return rec = DictConfig.find_by(dict_sys_name: dict_sys_name)
   end
end
