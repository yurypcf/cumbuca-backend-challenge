class TransactionsHandler
  include Transactions

  def initialize(transaction, action)
    @transaction = transaction
    @action = action
  end

  def perform
    case @action
    when :transfer
      Rails.logger.info "[TRANSACTION][PROCESSING] Starting TRANSFER"
      transfer = Transactions::Transfer.new(@transaction).perform
      transfer
    when :reverse
      Rails.logger.info "[TRANSACTION][PROCESSING] Starting REVERSAL"
      reversal = Transactions::Reversal.new(@transaction).perform
      reversal
    else
      # TODO: Update this else
      raise ApiError.new("TransactionsHandler dont have this action")
    end
  end
end