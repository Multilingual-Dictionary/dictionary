class DictJob < ApplicationRecord
  def create_new()
    self.percent=0
    self.status=""
    self.message=""
    self.notes=""
    if save
      return self.id
    end
    return 0
  end
end
