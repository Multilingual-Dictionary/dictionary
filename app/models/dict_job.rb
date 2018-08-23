class DictJob < ApplicationRecord
  def create_new()
    if save
      return self.id
    end
    return 0
  end
end
