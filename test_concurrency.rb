# TODO: transform this into rails task

require 'httparty'

document_number = "06424675019"
password = "123456"
base_uri = "http://localhost:3000"

user_account_params = {
  user_account: {
    name: "UserAccount",
    last_name: "Test",
    document_number: document_number,
    opening_balance: 50000, # 50000 cents = 500 reais
    password: password
  }
}

create_account_res = HTTParty.post(
  "#{base_uri}/create_user_account",
  body: user_account_params
)

sign_in_params = {
  document_number: document_number,
  password: password
}

sign_in_res = HTTParty.post(
  "#{base_uri}/sign_in",
  body: sign_in_params
)

token = JSON.parse(sign_in_res.body)['token']

headers = { "Authorization": "Bearer #{token}" }
params = { transaction: { amount: 100, receiver_document_number: "61356551084" } }

threads = []
transaction_ids = []

10.times {
  threads << Thread.new do
    transaction_res = HTTParty.post(
      "#{base_uri}/transaction",
      headers: headers,
      body: params
    )
    
    p transaction_res.body
    transaction_ids << JSON.parse(transaction_res.body)['transaction_id']
  end
}

threads.each(&:join)

transaction_ids.each do |t_id|
  reversal_res = HTTParty.post(
    "#{base_uri}/reverse_transaction",
    headers: headers,
    body: { transaction: { transaction_id: t_id } }
  )

  p reversal_res.body
end