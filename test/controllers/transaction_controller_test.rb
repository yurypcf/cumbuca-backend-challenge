require "test_helper"

class TransactionControllerTest < ActionDispatch::IntegrationTest
  def setup
    @sender = user_accounts(:ken_masters_account)
    @receiver = user_accounts(:ryu_hayabusa_account)

    @transaction_to_be_succesfully_refunded = transactions(:transaction_to_be_succesfully_refunded)
    @transaction_to_fail_refund = transactions(:transaction_to_fail_refund)
    @transaction_to_fail_refund_2 = transactions(:transaction_to_fail_refund_2)

    post "/user_accounts/sign_in",
      params: {
        document_number: "71370823002",
        password: "123456"
      }

    @token = JSON.parse(@response.body)['token']
  end

  test "should validate that doesnt have negative or zero balance" do
    @sender.update(balance: 0)

    assert_no_difference('Transaction.count') do
      post "/transactions/create",
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
      post "/transactions/create",
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
      post "/transactions/create",
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
      post "/transactions/create",
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
      post "/transactions/create",
        headers: {
          Authorization: "Bearer #{@token}"
        },
        params: {
          transaction: {
            receiver_document_number: @receiver.document_number, # changing document number to ryu hayabusa
            amount: 200
          }
        }
      transfer_id = JSON.parse(@response.body)['transaction_id']

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

  test "should not find a transaction to revert" do
    post "/transactions/reverse",
      headers: {
        Authorization: "Bearer #{@token}"
      },
      params: {
        transaction: {
          transaction_id: 111111
        }
      }
    assert_equal "{\"error\":\"Couldnt find Transaction without an ID\"}", @response.body
    assert_response :bad_request
  end

  test "should not revert a transaction with divergent account user author" do
    post "/transactions/reverse",
      headers: {
        Authorization: "Bearer #{@token}"
      },
      params: {
        transaction: {
          transaction_id: @transaction_to_fail_refund_2.id
        }
      }
    assert_equal "{\"error\":\"Transaction user account id doesnt match\"}", @response.body
    assert_response :bad_request
  end

  test "should not revert a transaction that isnt succesfull" do
    post "/transactions/reverse",
      headers: {
        Authorization: "Bearer #{@token}"
      },
      params: {
        transaction: {
          transaction_id: @transaction_to_fail_refund.id
        }
      }
    assert_equal "{\"error\":\"Transaction cant be reversed\"}", @response.body
    assert_response :bad_request
  end

  test "should not revert if receiver balance would be negative" do
    # Transaction to be reverted amount is 240 cents
    @receiver.update(balance: 120)

    post "/transactions/reverse",
      headers: {
        Authorization: "Bearer #{@token}"
      },
      params: {
        transaction: {
          transaction_id: @transaction_to_be_succesfully_refunded.id
        }
      }
    assert_equal "{\"error\":\"Transaction cant be reversed\"}", @response.body
    assert_response :bad_request
  end

  test "should revert a transaction succesfully" do
    # Transaction to be reverted amount is 240 cents

    reverter_balance = @sender.balance
    receiver_balance = @receiver.balance

    post "/transactions/reverse",
      headers: {
        Authorization: "Bearer #{@token}"
      },
      params: {
        transaction: {
          transaction_id: @transaction_to_be_succesfully_refunded.id
        }
      }
    reversal_id = JSON.parse(@response.body)['reversed_transaction_id']

    # ASSERT TRANSACTION EFFECTS
    reversal = Transaction.find_by(id: reversal_id)

    assert reversal.valid?
    assert reversal.reversal?
    assert reversal.success?
    
    # GET RECEIVER AND SENDER UPDATED USER ACCOUNT      
    receiver_balance = UserAccount.find(@receiver.id).balance
    sender_balance = UserAccount.find(@sender.id).balance

    # ASSERT NEW FINANCIAL BALANCE VALUES
    assert_equal @receiver.opening_balance - reversal.amount, receiver_balance
    assert_equal @sender.opening_balance + reversal.amount, sender_balance
  end
end
