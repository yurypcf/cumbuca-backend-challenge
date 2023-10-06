class CreateUserAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :user_accounts, id: :uuid do |t|
      t.string :name, null: false, limit: 65
      t.string :last_name, limit: 65
      t.string :document_number, null: false, limit: 11
      t.string :password_digest, null: false
      t.integer :balance, null: false
      t.integer :opening_balance, :default => 0
      t.timestamps
    end
  end
end
