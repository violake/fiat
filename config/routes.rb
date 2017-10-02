Rails.application.routes.draw do

  get '/deposits', to: 'deposits#index'
  get '/deposits/:id', to: 'deposits#show'

  get '/payments', to: 'payments#index'
  get '/payments/export', to: 'payments#export'
  get '/payments/:id', to: 'payments#show'
  put '/payments/:id', to: 'payments#update'
  post '/payments', to: 'payments#import'
  post '/payments/archive', to:'payments#archive'

  if Rails.env.development? || Rails.env.test?
    get '/fake_session', to:'application#fake_session'
  end
end
