class ApplicationController < ActionController::API

  rescue_from JWT::VerificationError, :with => :jwt_error
  rescue_from JWT::DecodeError, :with => :jwt_error
  rescue_from NoMethodError, :with => :no_authorization_header_error

  private

  def authorize
    authorization_header = request.headers['Authorization']
    
    token = authorization_header&.split(" ").last

    decoded_token = JwtWrapper.decode(token)

    user_id = decoded_token[:user_id]

    @user_account = UserAccount
      .where(["id = ?", user_id])
      .select("name, last_name, document_number, balance, opening_balance")
      .first
  end

  def jwt_error
    json_error("Invalid Authorization Token", :unauthorized)
  end

  def no_authorization_header_error
    json_error("No authorization header provided", :bad_request)
  end

  def json_error(message, status)
    render json: { error: message }, status: status.to_sym
  end
end
