Rails.application.routes.draw do
  post '/create_user_account', to: 'user_account#create'
  post '/sign_in',             to: 'user_account#sign_in'
  get  '/me',                  to: 'user_account#show'
end
