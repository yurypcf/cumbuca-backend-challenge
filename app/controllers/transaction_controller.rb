class TransactionController < ApplicationController
  before_action :authorize

  def index
    start_date, end_date = validate_date_input

    transactions = Transaction.report(start_date, end_date, @user_account.id)

    render json: { transactions: transactions, start_date: start_date, end_date: end_date }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  def create
    transaction = validate_transfer_params(transaction)
    receiver_account = validate_receiver_account(transaction.receiver_document_number)

    transaction.receiver_id = receiver_account.id
    transaction.sender_id = @user_account.id

    transfer = TransactionsHandler.new(transaction, :transfer).perform
    render json: { transaction_id: transfer.id }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  def reverse
    transaction = validate_reversal_params
    reversal = TransactionsHandler.new(transaction, :reverse).perform
    render json: { reversed_transaction_id: reversal.id }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  private

  # TODO: ALL VALIDATION METHODS SHOULD BE MOVED
  def validate_transfer_params(transaction)
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

  def validate_reversal_params
    transaction = Transaction.find_by(id: reversal_transaction_params[:transaction_id])

    # CHECK IF TRANSACTION IS IN DATABASE
    raise ApiError.new("Couldnt find Transaction without an ID", :bad_request) if transaction.nil?

    # CHECK IF REVERSAL AUTHOR IS THE SAME AUTHOR FROM ORIGINAL TRANSACTION
    raise ApiError.new("Transaction user account id doesnt match", :bad_request) if transaction.sender_id != @user_account.id

    # REVERT ONLY SUCCESFULL TRANSACTIONS
    raise ApiError.new("Transaction cant be reversed", :bad_request) unless transaction.success? && transaction.transfer?

    user_account_balance = UserAccount.find_by(id: transaction.receiver_id).balance

    raise ApiError.new("Transaction cant be reversed", :bad_request) if user_account_balance - transaction.amount < 0

    transaction
  end

  def validate_date_input
    raise ApiError.new('No date filter provided', :bad_request) if index_params[:start_date].nil? || index_params[:end_date].nil?

    start_date = index_params[:start_date]
    end_date = index_params[:end_date]

    raise ApiError.new('Date input must be formated yyyy-mm-dd or yyyy-m-d', :bad_request) unless match_date_format?(start_date) && match_date_format?(end_date)

    [DateTime.parse(start_date), DateTime.parse(end_date)]
  end

  def match_date_format?(str)
    str =~ /^\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])$/
  end

  def transfer_transaction_params
    params.require(:transaction).permit(:receiver_document_number, :amount)
  end

  def reversal_transaction_params
    params.require(:transaction).permit(:transaction_id)
  end

  def index_params
    params.permit(:start_date, :end_date, transaction: {})
  end
end
