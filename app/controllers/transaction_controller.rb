class TransactionController < ApplicationController
  before_action :authorize

  def create
    transaction = validate_transaction_before_action(transaction)

    # CHECK IF USER ACCOUNT EXISTS
    receiver_account = UserAccount.find_by(document_number: transaction.receiver_document_number)

    if receiver_account
      # CHECK IF ISNT A SELF TRANSFER
      if receiver_account.id == @user_account.id
        raise ApiError.new('You can not transfer to yourself', :bad_request)
      end

      transaction.receiver_id = receiver_account.id
      transaction.sender_id = @user_account.id

      t = TransactionsHandler.new(transaction).perform
      render json: { transaction: t }, status: :ok
    else
      # receiver account not found
      raise ApiError.new('Receiver Account not found', :bad_request)
    end
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  private

  def validate_transaction_before_action(transaction)
    # CHECK SENDER BALANCE
    if @user_account.balance < 1
      raise ApiError.new('Insufficient funds', :bad_request)
    end

    transaction = Transaction.new(transaction_params)

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

  def transaction_params
    params.require(:transaction).permit(:receiver_document_number, :amount)
  end
end
