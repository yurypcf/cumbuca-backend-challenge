class ApiError < StandardError
  attr_reader :http_status

  def initialize(message, http_status = nil)
    Rails.logger.error message
    super(message)
    @http_status = http_status
  end
end