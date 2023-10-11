class TransactionController < ApplicationController
  before_action :authorize

  def index
    Rails.logger.info "[TRANSACTION][VALIDATION] Started POST /transactions"
    start_date, end_date = validate_date_input

    Rails.logger.info "[TRANSACTION][PROCESSING] Gathering transactions..."
    transactions = Transaction.report(start_date, end_date, @user_account.id)

    Rails.logger.info "[TRANSACTION][SUCCESS] Report OK"
    render json: { transactions: transactions, start_date: start_date, end_date: end_date }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  def create
    Rails.logger.info "[TRANSACTION][VALIDATION] Validating receiver account"
    receiver_account = TransactionsHandler.validate_receiver_account(
      transfer_transaction_params[:receiver_document_number],
      @user_account.id
    )

    Rails.logger.info "[TRANSACTION][VALIDATION] Validating transaction params"
    transaction = TransactionsHandler.validate_transfer(@user_account, transfer_transaction_params)

    transfer = TransactionsHandler.new(transaction, :transfer).perform
    Rails.logger.info "[TRANSACTION][SUCCESS] Transfer ID: #{transfer.id}"
    render json: { transaction_id: transfer.id }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  def reverse
    Rails.logger.info "[TRANSACTION][VALIDATION] Validating reverse transaction params"
    transaction = TransactionsHandler.validate_reversal(
      reversal_transaction_params[:transaction_id],
      @user_account.id
    )

    reversal = TransactionsHandler.new(transaction, :reverse).perform
    Rails.logger.info "[TRANSACTION][SUCCESS] Reversal ID: #{reversal.id}"
    render json: { reversed_transaction_id: reversal.id }, status: :ok
  rescue StandardError => exception
    error = ApiError.new(exception.message, :bad_request)
    render json: { error: error.message }, status: error.http_status
  end

  private

  def validate_date_input
    raise ApiError.new('No date filter provided', :bad_request) if index_params[:start_date].nil? || index_params[:end_date].nil?

    start_date = index_params[:start_date]
    end_date = index_params[:end_date]

    raise ApiError.new('Date input must be formated yyyy-mm-dd or yyyy-m-d', :bad_request) unless match_date_format?(start_date) && match_date_format?(end_date)

    [Time.zone.parse(start_date), Time.zone.parse(end_date)]
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
