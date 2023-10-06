require "test_helper"

class JwtWrapperTest < ActiveSupport::TestCase
  test "should create a token with provided UserAccount" do
    user_account = user_accounts(:ryu_hayabusa_account)

    jwt_data = {
      user_id:         user_account.id,
      document_number: user_account.document_number,
      password_digest: user_account.password_digest
    }

    token = JwtWrapper.encode(jwt_data)

    decoded_token_data = JwtWrapper.decode(token)

    assert_equal "1e9a754c-bac5-4ee3-8f8b-035a76693bc8", decoded_token_data[:user_id]
    assert_equal "38426879586", decoded_token_data[:document_number]
    assert_equal "123456", decoded_token_data[:password_digest]
  end
end