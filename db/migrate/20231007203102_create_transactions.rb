class CreateTransactions < ActiveRecord::Migration[7.0]
  def change
    create_enum :transaction_transaction_type, ["transfer", "reversal"]
    create_enum :transaction_status, ["processing", "success", "failed", "reversed"]

    create_table :transactions, id: :uuid do |t|
      t.references :sender, type: :uuid, references: :user_accounts, foreign_key: { to_table: :user_accounts }
      t.string :receiver_id, null: false
      t.string :receiver_document_number, null: false, limit: 11
      t.integer :amount, null: false
      t.enum :transaction_type, enum_type: "transaction_transaction_type", default: "transfer", null: false
      t.enum :status, enum_type: "transaction_status", default: "processing", null: false
      t.timestamps
    end
  end
end