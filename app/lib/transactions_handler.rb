class TransactionsHandler
  include Transactions

  def initialize(transaction)
    @transaction = transaction
    @action = transaction.transaction_type.to_sym
  end

  def perform
    case @action
    when :transfer
      transfer = Transactions::Transfer.new(@transaction).perform
      transfer
    when :reverse
      # Transactions::Reverse.new(transaction)
    else
      raise ApiError.new("TransactionsHandler dont have this action")
    end
  end
end