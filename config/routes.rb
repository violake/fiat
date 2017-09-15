Rails.application.routes.draw do

  get '/deposits', to: 'deposits#index'
  get '/deposits/:id', to: 'deposits#show'

  get '/payments', to: 'payments#index'
  get '/payments/:id', to: 'payments#show'
  put '/payments/:id', to: 'payments#update'
  post '/payments', to: 'payments#import'
end
