Rails.application.routes.draw do
  # UserAccount related routes
  post '/create_user_account', to: 'user_account#create'
  post '/sign_in',             to: 'user_account#sign_in'
  get  '/me',                  to: 'user_account#show'

  # Transaction related routes
  post '/reverse_transaction', to: 'transaction#reverse'
  post '/transaction',         to: 'transaction#create'
  #get  '/transactions',        to:
end
