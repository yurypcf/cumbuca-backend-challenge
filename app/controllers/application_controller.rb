class ApplicationController < ActionController::API

  private

  def authorize
    authorization_header = request.headers['Authorization']
    
    raise ApiError.new("No authorization token provided", :unauthorized) if authorization_header.nil?

    token = authorization_header.split(" ").last

    decoded_token = JwtWrapper.decode(token)

    user_id = decoded_token[:user_id]

    @user_account = UserAccount.find(user_id)
  rescue StandardError => exception
    error = ApiError.new(exception.message, :unauthorized)
    render json: { error: error.message }, status: error.http_status
  end
end
