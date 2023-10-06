require "test_helper"

class UserAccountTest < ActiveSupport::TestCase
  test "should not save invalid UserAccount" do
    user_account = UserAccount.new
    assert_not user_account.save
  end

  test "should save a valid UserAccount" do
    opening_balance = 10000

    user_account = UserAccount.new(
      name: "Yury",
      document_number: "71313210013",
      opening_balance: opening_balance,
      balance: opening_balance,
      password: "123456"
    )

    assert user_account.save
  end

  test "should not save UserAccount with exceeding lengths" do
    opening_balance = 10000

    user_account = UserAccount.new(
      name: "Yury",
      document_number: "30328329329328329",
      opening_balance: opening_balance,
      balance: opening_balance,
      password: "123456"
    )

    # invalid user account with document number greater than 11
    refute user_account.valid?


    # fixing document number length so it can be a valid record
    user_account.update(document_number: "71313210013")
    assert user_account.valid?, true


    # exceeding the record name length so it becomes invalid again
    user_account.update(name: "Solid Snake Liquid Snake Solidus Snake Raiden Revolver Ocelot Kazuhira Miller")
    refute user_account.valid?
  end
end
