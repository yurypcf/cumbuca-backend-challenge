class UserAccount < ApplicationRecord
  has_secure_password

  validates :name, presence: true, length: { maximum: 65 }
  validates :last_name, length: { maximum: 65 }
  validates :document_number, presence: true, length: { minimum: 11, maximum: 11 }, uniqueness: true
  validates :opening_balance, presence: true
end
