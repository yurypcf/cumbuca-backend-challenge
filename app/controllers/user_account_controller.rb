class UserAccountController < ApplicationController
  def create
    @user_account = UserAccount.new(user_account_params)

    if @user_account.valid?
      @user_account.balance = @user_account.opening_balance
      @user_account.save

      head :created
    else
      head :unprocessable_entity
    end
  end

  def sign_in
    user_account = UserAccount.find_by(document_number: params[:document_number])
    
    if user_account&.authenticate(params[:password])
      token = JwtWrapper.encode(
        user_id: user_account.id,
        document_number: user_account.document_number
      )

      expire_time = JwtWrapper.decode(token)[:exp]

      render json: { token: token, expire_time: Time.at(expire_time) }, status: :ok
    else
      render json: { error: 'invalid user or password' }, status: :unauthorized
    end
  end

  private

  def user_account_params
    params.require(:user_account).permit(:name, :last_name, :document_number, :opening_balance, :password)
  end
end
