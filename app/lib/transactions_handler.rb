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

  def self.validate_receiver_account(document_number, user_account_id)
    receiver_account = UserAccount.find_by!(document_number: document_number)

    # CHECK IF RECEIVER ACCOUNT EXISTS
    raise ApiError.new('Receiver Account not found', :bad_request) if receiver_account.nil?

    # CHECK IF ISNT SELF TRANSFER
    raise ApiError.new('You can not transfer to yourself', :bad_request) if receiver_account.id == user_account_id

    receiver_account
  end

  def self.validate_transfer(user_account, transfer_params)
    # CHECK SENDER BALANCE
    if user_account.balance < 1
      raise ApiError.new('Insufficient funds', :bad_request)
    end

    # CHECK IF TRANSACTION AMOUNT IS GREATER THAN 1 CENT
    if transfer_params[:amount].nil? || transfer_params[:amount].to_i < 1
      raise ApiError.new('Invalid amount or amount not supplied', :bad_request)
    end

    # CHECK IF THE TRANSFER IS MATHEMATICALLY POSSIBLE
    if transfer_params[:amount].to_i > user_account.balance
      raise ApiError.new('Amount supplied greater than SENDER UserAccount funds', :bad_request)
    end

    transaction = Transaction.new(transfer_params)

    receiver_id = UserAccount.find_by!(document_number: transfer_params[:receiver_document_number]).id

    transaction.receiver_id = receiver_id
    transaction.sender_id = user_account.id

    transaction
  end

  def self.validate_reversal(transaction_id, user_account_id)
    transaction = Transaction.find_by(id: transaction_id)

    # CHECK IF TRANSACTION IS IN DATABASE
    raise ApiError.new("Couldnt find Transaction without an ID", :bad_request) if transaction.nil?

    # CHECK IF REVERSAL AUTHOR IS THE SAME AUTHOR FROM ORIGINAL TRANSACTION
    raise ApiError.new("Transaction user account id doesnt match", :bad_request) if transaction.sender_id != user_account_id

    # REVERT ONLY SUCCESFULL TRANSACTIONS
    raise ApiError.new("Transaction cant be reversed", :bad_request) unless transaction.success? && transaction.transfer?

    receiver_balance = UserAccount.find_by(id: transaction.receiver_id).balance

    raise ApiError.new("Transaction cant be reversed", :bad_request) if receiver_balance - transaction.amount < 0

    transaction
  end
end