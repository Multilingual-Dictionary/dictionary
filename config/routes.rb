require 'sidekiq/web'
Rails.application.routes.draw do

  get 'sessions/new'

  get 'users/new'

  resources :data_files
  resources :dict_jobs
  resources :glossary_indices
  resources :progress_bars
  resources :users
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
  get '/home',    to: 'dict_pages#home'
  get '/help',    to: 'dict_pages#help'
  get '/about',   to: 'dict_pages#about'
  get '/error',   to: 'dict_pages#error'
  get '/admin',   to: 'dict_pages#admin'
  get '/signup',   to: 'users#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'
  get '/logout',  to: 'sessions#destroy'
  get '/dict_lookup',   to: 'dict_pages#dict_lookup'
  get '/dict_add',   to: 'dict_pages#dict_add'
  put '/glossaries',   to: 'glossaries#index'
  get '/progress' => 'dict_jobs#progress'

#  put  '/davkhkt_dicts',   to: 'davkhkt_dicts#index'
#  get 'dav_dict_pages/import'
#  get 'dav_dict_pages/show'
#  put  '/dict_import',   to: 'import_page#import_glossary'
#  get  '/dict_import',   to: 'import_page#import_glossary'
#  put  '/dict_import_commit',   to: 'import_page#import_glossary_commit'
#  get  '/dict_import_commit',   to: 'import_page#import_glossary_commit'
#  get 'export_glossaries' => 'exports#export_glossaries', as: :export_glossaries

mount Sidekiq::Web, at: "/sidekiq"
end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
