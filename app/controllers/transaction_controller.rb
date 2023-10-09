class TransactionController < ApplicationController
  before_action :authorize

  def create
    transaction = validate_transaction_params(transaction)
    receiver_account = validate_receiver_account(transaction.receiver_document_number)

    transaction.receiver_id = receiver_account.id
    transaction.sender_id = @user_account.id

    transfer = TransactionsHandler.new(transaction, :transfer).perform
    render json: { transaction_id: transfer.id }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  private

  def validate_transaction_params(transaction)
    # CHECK SENDER BALANCE
    if @user_account.balance < 1
      raise ApiError.new('Insufficient funds', :bad_request)
    end

    transaction = Transaction.new(transfer_transaction_params)

    # CHECK IF TRANSACTION AMOUNT IS GREATER THAN 1 CENT
    if transaction.amount.nil? || transaction.amount < 1
      raise ApiError.new('Invalid amount or amount not supplied', :bad_request)
    end

    # CHECK IF THE TRANSFER IS MATHEMATICALLY POSSIBLE
    if transaction.amount > @user_account.balance
      raise ApiError.new('Amount supplied greater than SENDER UserAccount funds', :bad_request)
    end

    transaction
  end

  def validate_receiver_account(document_number)
    receiver_account = UserAccount.find_by(document_number: document_number)

    # CHECK IF RECEIVER ACCOUNT EXISTS
    raise ApiError.new('Receiver Account not found', :bad_request) if receiver_account.nil?

    # CHECK IF ISNT SELF TRANSFER
    raise ApiError.new('You can not transfer to yourself', :bad_request) if receiver_account.id == @user_account.id

    receiver_account
  end

  def transfer_transaction_params
    params.require(:transaction).permit(:receiver_document_number, :amount)
  end

  def reversal_transaction_params
    params.require(:transaction).permit(:receiver_document_number, :amount)
  end
end
