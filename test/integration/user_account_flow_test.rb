require "test_helper"

class UserAccountFlowTest < ActionDispatch::IntegrationTest
  test "create user account and sign in" do
    assert_difference('UserAccount.count') do
      post "/create_user_account",
        params: {
          user_account: {
            name: "Kaneda",
            last_name: "Shotaro",
            document_number: "85902023050",
            password: "123456"
          }
        }
      assert_response :created

      post "/sign_in",
      params: {
        document_number: "85902023050",
        password: "123456"
      }
    
      refute @response.body.nil?
      assert_response :ok

      sign_in_body_json = JSON.parse(@response.body)
      get "/me", headers: { Authorization: "Bearer #{sign_in_body_json['token']}"}
      assert_response :ok

      assert_equal "85902023050", JSON.parse(@response.body)['user_account']['document_number']
    end
  end
end
