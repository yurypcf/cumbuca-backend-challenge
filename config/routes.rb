Rails.application.routes.draw do
  # UserAccount related routes
  post '/user_accounts/sign_in', to: 'user_account#sign_in'
  get  '/user_accounts/me',      to: 'user_account#show'
  post '/user_accounts',         to: 'user_account#create'

  # Transaction related routes
  post '/transactions/reverse', to: 'transaction#reverse'
  post '/transactions/create',  to: 'transaction#create'
  post '/transactions',         to: 'transaction#index'
end
