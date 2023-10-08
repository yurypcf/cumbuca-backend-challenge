require "test_helper"

class TransactionControllerTest < ActionDispatch::IntegrationTest
  def setup
    @sender = user_accounts(:ken_masters_account)
    @receiver = user_accounts(:ryu_hayabusa_account)

    post "/sign_in",
      params: {
        document_number: "71370823002",
        password: "123456"
      }

    @token = JSON.parse(@response.body)['token']
  end

  test "should validate that doesnt have negative or zero balance" do
    @sender.update(balance: 0)

    assert_no_difference('Transaction.count') do
      post "/transaction",
        headers: {
          Authorization: "Bearer #{@token}"
        },
        params: {
          transaction: {
            receiver_document_number: @receiver.document_number,
            amount: 200
          }
        }
      assert_equal "{\"error\":\"Insufficient funds\"}", @response.body
      assert_response :bad_request
    end
  end

  test "should validate sender provided amount or greater than 0 amount" do
    assert_no_difference('Transaction.count') do
      post "/transaction",
        headers: {
          Authorization: "Bearer #{@token}"
        },
        params: {
          transaction: {
            receiver_document_number: @receiver.document_number
          }
        }
      assert_equal "{\"error\":\"Invalid amount or amount not supplied\"}", @response.body
      assert_response :bad_request
    end
  end
  
  test "should validate that transfer amount is NOT greater than sender balance" do
    @sender.update(balance: 100)

    assert_no_difference('Transaction.count') do
      post "/transaction",
        headers: {
          Authorization: "Bearer #{@token}"
        },
        params: {
          transaction: {
            receiver_document_number: @receiver.document_number,
            amount: 200
          }
        }
      assert_equal "{\"error\":\"Amount supplied greater than SENDER UserAccount funds\"}", @response.body
      assert_response :bad_request
    end
  end

  test "should validate isnt a self transfer" do
    assert_no_difference('Transaction.count') do
      post "/transaction",
        headers: {
          Authorization: "Bearer #{@token}"
        },
        params: {
          transaction: {
            receiver_document_number: @sender.document_number, # changing document number to ryu hayabusa
            amount: 200
          }
        }
      assert_equal "{\"error\":\"You can not transfer to yourself\"}", @response.body
      assert_response :bad_request
    end
  end

  test "should be able to create a succesfull transfer" do
    assert_difference('Transaction.count') do
      post "/transaction",
        headers: {
          Authorization: "Bearer #{@token}"
        },
        params: {
          transaction: {
            receiver_document_number: @receiver.document_number, # changing document number to ryu hayabusa
            amount: 200
          }
        }
      transfer_id = JSON.parse(@response.body)['transaction']['id']

      # ASSERT TRANSACTION EFFECTS
      transfer = Transaction.find_by(id: transfer_id)
  
      assert transfer.valid?
      assert transfer.transfer?
      assert transfer.success?
      
      # GET RECEIVER AND SENDER UPDATED USER ACCOUNT      
      receiver_balance = UserAccount.find(@receiver.id).balance
      sender_balance = UserAccount.find(@sender.id).balance

      # ASSERT NEW FINANCIAL BALANCE VALUES
      assert_equal transfer.amount + @receiver.opening_balance, receiver_balance
      assert_equal @sender.opening_balance - transfer.amount, sender_balance
    end
  end
end
