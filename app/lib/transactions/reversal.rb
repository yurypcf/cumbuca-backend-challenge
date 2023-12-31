module Transactions
  class Reversal
    def initialize(transaction)
      @transaction = transaction
    end

    def perform
      ActiveRecord::Base.transaction(isolation: :serializable) do
        amount_to_be_reversed = @transaction.amount
        receiver_account = UserAccount.find(@transaction.receiver_id)

        reverser_account = UserAccount.find(@transaction.sender_id)

        receiver_new_balance = receiver_account.balance - amount_to_be_reversed
        receiver_account.update(balance: receiver_new_balance)

        reverser_new_balance = reverser_account.balance + amount_to_be_reversed
        reverser_account.update(balance: reverser_new_balance)

        if reverser_account.balance == reverser_new_balance && receiver_account.balance == receiver_new_balance
          receiver_account.save!
          reverser_account.save!
          @transaction.success!
          @transaction.reversal!
        else
          @transaction.reversed_failed!
          raise ActiveRecord::Rollback
        end
      end

      @transaction
    end
  end
end