Rails.application.routes.draw do
  get 'admin_pages/admin_home'

  get 'admin_pages/config_dict'

  get 'admin_pages/config_user'

  root 'dict_pages#home'
  get  '/home',    to: 'dict_pages#home'
  get  '/help',    to: 'dict_pages#help'
  get  '/about',   to: 'dict_pages#about'
  get  '/admin',   to: 'dict_pages#admin'
end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
