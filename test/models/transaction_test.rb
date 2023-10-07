require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @ryu_account = user_accounts(:ryu_hayabusa_account)
    @ken_account = user_accounts(:ken_masters_account)
  end

  test "should not save invalid Transaction" do
    transaction = Transaction.new(sender_id: @ryu_account.id)
    assert_not transaction.save
  end

  test "should save a valid Transaction" do
    transaction = Transaction.new(
      sender_id: @ken_account.id,
      receiver_id: @ryu_account.id,
      receiver_document_number: @ryu_account.document_number,
      amount: 20000,
      transaction_type: "transfer", # default value, it can be created without exposing, but its here for clarity
      status: "processing", # default value, it can be created without exposing, but its here for clarity
    )

    assert transaction.save
  end

  test "should not save with characters in amount column" do
    transaction = Transaction.new(
      sender_id: @ken_account.id,
      receiver_id: @ryu_account.id,
      receiver_document_number: @ryu_account.document_number,
      amount: "abcdefg",
      transaction_type: :transfer, # default value, it can be created without exposing, but its here for clarity
      status: :processing, # default value, it can be created without exposing, but its here for clarity
    )

    assert_not transaction.save
  end

  test "should not save with characters in receiver document numer column" do
    transaction = Transaction.new(
      sender_id: @ken_account.id,
      receiver_id: @ryu_account.id,
      receiver_document_number: "abcdefgHIJK",
      amount: 500,
      transaction_type: :transfer, # default value, it can be created without exposing, but its here for clarity
      status: :processing, # default value, it can be created without exposing, but its here for clarity
    )

    assert_not transaction.save
  end
end
