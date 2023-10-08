class ApiError < StandardError
  # TODO: Provide RAILS LOGS here
  attr_reader :http_status

  def initialize(message, http_status = nil)
    super(message)
    @http_status = http_status
  end
end