class UserAccount < ApplicationRecord
  has_secure_password
  has_many :transactions

  validates :name, presence: true, length: { maximum: 65 }
  validates :last_name, length: { maximum: 65 }
  validates :document_number, presence: true, length: { minimum: 11, maximum: 11 }, numericality: { only_integer: true }, uniqueness: true
  validates :opening_balance, presence: true, numericality: { only_integer: true }
end
