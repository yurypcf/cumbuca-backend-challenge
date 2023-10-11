require "test_helper"

class TransactionsFlowTest < ActionDispatch::IntegrationTest
  test "create transactions, refund and get report" do
    post "/user_accounts/sign_in",
    params: {
      document_number: user_accounts(:ryu_hayabusa_account).document_number,
      password: "123456"
    }
  
    refute @response.body.nil?
    assert_response :ok

    token = JSON.parse(@response.body)['token']

    post "/transactions/create",
      headers: {
        Authorization: "Bearer #{token}"
      },
      params: {
        transaction: {
          receiver_document_number: user_accounts(:ken_masters_account).document_number, # changing document number to ryu hayabusa
          amount: 100
        }
      }

    transfer_id = JSON.parse(@response.body)['transaction_id']

    # ASSERT TRANSACTION EFFECTS
    transfer = Transaction.find_by(id: transfer_id)

    assert transfer.valid?
    assert transfer.transfer?
    assert transfer.success?


    post "/transactions/reverse",
    headers: {
      Authorization: "Bearer #{token}"
    },
    params: {
      transaction: {
        transaction_id: transfer_id
      }
    }
    reversal_id = JSON.parse(@response.body)['reversed_transaction_id']

    # ASSERT TRANSACTION EFFECTS
    reversal = Transaction.find_by(id: reversal_id)

    assert reversal.valid?
    assert reversal.reversal?
    assert reversal.success?

    todays_date = Time.now.strftime("%Y-%m-%d")

    post "/transactions",
    headers: {
      Authorization: "Bearer #{token}"
    },
    params: {
      start_date: todays_date,
      end_date: todays_date
    }

    json_transactions_report = JSON.parse(@response.body)['transactions']
    refute json_transactions_report.nil?

    assert_equal Transaction.where(sender_id: transfer.sender_id).count, json_transactions_report.count
  end
end
