require "test_helper"

class UserAccountControllerTest < ActionDispatch::IntegrationTest
  test "should not create user account with invalid post parameters" do
    assert_no_difference('UserAccount.count') do
      post "/create_user_account",
        params: {
          user_account: {
            name: "Kaneda",
            last_name: "Shotaro",
            document_number:"85902023050545454543", # document_number greater than permitted
            password: "123456"
          }
        }
      assert_response :unprocessable_entity

      post "/create_user_account",
        params: {
          user_account: {
            # mandatory field name not provided
            last_name: "Shotaro",
            document_number:"85902023050",
            password: "123456"
          }
        }
      assert_response :unprocessable_entity
    end
  end

  test "should create a valid user account and fail to sign_in providing incorret credentials" do
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
    end

    # failing sign_in
    post "/sign_in",
      params: {
        document_number: "85902223050", # wrong document_number
        password: "123456"
      }
    assert_response :unauthorized
  end

  test "should be able succesfull create user account" do
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
    end
  end

  test "should be able to succesfull sign in" do
    post "/sign_in",
      params: {
        document_number: user_accounts(:ryu_hayabusa_account).document_number,
        password: "123456"
      }
    
    refute @response.body.nil?
    assert_response :ok
  end
end
