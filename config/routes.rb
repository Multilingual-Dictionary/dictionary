Rails.application.routes.draw do

  resources :progress_bars
  get 'export_glossary/export'

  resources :glossaries
  resources :davkhkt_dicts
  resources :dict_configs
  root 'dict_pages#home'
  get 'admin_pages/admin_home'
  get 'admin_pages/config_dict'
  get 'admin_pages/config_user'
  get 'dav_dict_pages/import'
  get 'dav_dict_pages/show'
  get  '/home',    to: 'dict_pages#home'
  get  '/help',    to: 'dict_pages#help'
  get  '/about',   to: 'dict_pages#about'
  get  '/admin',   to: 'dict_pages#admin'
  get  '/dict_lookup',   to: 'dict_pages#dict_lookup'
  put  '/davkhkt_dicts',   to: 'davkhkt_dicts#index'
  put  '/glossaries',   to: 'glossaries#index'
  put  '/dict_import',   to: 'import_page#import_glossary'
  get  '/dict_import',   to: 'import_page#import_glossary'
  put  '/dict_import_commit',   to: 'import_page#import_glossary_commit'
  get  '/dict_import_commit',   to: 'import_page#import_glossary_commit'
  get 'export_glossaries' => 'exports#export_glossaries', as: :export_glossaries
end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
