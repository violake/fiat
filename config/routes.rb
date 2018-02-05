Rails.application.routes.draw do

  get '/deposits', to: 'deposits#index'
  get '/deposits/:id', to: 'deposits#show'

  get '/transfer_ins', to: 'transfer_ins#index'
  get '/transfer_ins/export', to: 'transfer_ins#export'
  get '/transfer_ins/:id', to: 'transfer_ins#show'
  put '/transfer_ins/:id', to: 'transfer_ins#update'
  post '/transfer_ins', to: 'transfer_ins#import'
  post '/transfer_ins/archive', to:'transfer_ins#archive'
  post '/transfer_ins/:id/reconcile', to: 'transfer_ins#force_reconcile'

  if Rails.env.development? || Rails.env.test?
    get '/fake_session', to:'application#fake_session'
  end
end
