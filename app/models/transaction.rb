class Transaction < ApplicationRecord
  belongs_to :user_account, foreign_key: "sender_id"

  enum transaction_type: { transfer: 'transfer', reversal: 'reversal'}
  enum status: {
    processing: 'processing',
    success: 'success',
    failed: 'failed',
    reverse_failed: 'reverse_failed'
  }

  validates :sender_id, presence: true
  validates :receiver_id, presence: true
  validates :receiver_document_number, presence: true, length: { minimum: 11, maximum: 11 }, numericality: { only_integer: true }
  validates :amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :report, -> (start_date, end_date, account_user_id) {
    where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    .where(sender_id: account_user_id)
    .order(created_at: :desc)
  }
end
