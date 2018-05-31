Rails.application.routes.draw do
  get 'dict_pages/home'

  get 'dict_pages/help'

  get 'dict_pages/about'

  get 'dict_pages/admin'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'application#hello'

end
