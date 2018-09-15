require 'sidekiq/web'
Rails.application.routes.draw do

  resources :data_files
  resources :dict_jobs
  resources :glossary_indices
  resources :progress_bars
  get 'export_glossary/export'
  get 'export_glossary/export_now'

  resources :glossaries
  resources :davkhkt_dicts
  resources :dict_configs
  root 'dict_pages#home'
  get 'admin_pages/admin_home'
  get 'admin_pages/config_dict'
  get 'admin_pages/config_dict_new'
  get 'admin_pages/config_dicts'
  get 'admin_pages/glossaries'
  get 'admin_pages/glossary_edit'
  get 'admin_pages/glossary_import'
  put 'admin_pages/glossary_import'
  get 'admin_pages/glossary_export'
  put 'admin_pages/glossary_export'
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
  get '/progress' => 'dict_jobs#progress'

mount Sidekiq::Web, at: "/sidekiq"
end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
