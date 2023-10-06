require 'jwt'

class JwtWrapper
  SECRET_KEY = Rails.application.secrets.secret_key_base

  def self.encode(payload)
    payload[:exp] = 20.minutes.from_now.to_i # 20 minutes expiry 

    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body = JWT.decode(token, SECRET_KEY)[0]

    HashWithIndifferentAccess.new(body)
  end
end