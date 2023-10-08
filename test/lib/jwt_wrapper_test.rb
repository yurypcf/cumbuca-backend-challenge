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

    assert_equal user_account.id, decoded_token_data[:user_id]
    assert_equal user_account.document_number, decoded_token_data[:document_number]
    assert_equal user_account.password_digest, decoded_token_data[:password_digest]
  end
end