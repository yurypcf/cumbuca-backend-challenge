module Transactions
  class Transfer
    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      sender_account = UserAccount.find(@transaction.sender_id)
      receiver_account = UserAccount.find(@transaction.receiver_id)

      ActiveRecord::Base.transaction do
        sender_new_balance = sender_account.balance - @transaction.amount
        sender_account.update(balance: sender_new_balance)
        
        receiver_new_balance = receiver_account.balance + @transaction.amount
        receiver_account.update(balance: receiver_new_balance)
        
        if sender_account.balance == sender_new_balance && receiver_account.balance == receiver_new_balance
          sender_account.save!
          receiver_account.save!
        else
          @transaction.failed!
          raise ActiveRecord::Rollback
        end

        @transaction.success!
      end

      @transaction
    end
  end
end