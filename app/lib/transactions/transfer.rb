module Transactions
  class Transfer
    def initialize(transaction)
      @transaction = transaction
    end

    def perform      
      ActiveRecord::Base.transaction(isolation: :serializable) do
        sender_account = UserAccount.find(@transaction.sender_id)

        receiver_account = UserAccount.find(@transaction.receiver_id)

        sender_new_balance = sender_account.balance - @transaction.amount
        sender_account.update(balance: sender_new_balance)
        
        receiver_new_balance = receiver_account.balance + @transaction.amount
        receiver_account.update(balance: receiver_new_balance)
        
        if sender_account.balance == sender_new_balance && receiver_account.balance == receiver_new_balance
          sender_account.save!
          receiver_account.save!
          @transaction.success!
        else
          @transaction.failed!
          raise ActiveRecord::Rollback
        end

      end

      @transaction
    end
  end
end