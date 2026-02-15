# frozen_string_literal: true

# Log request and response details for monitoring and high-level profiling.
#
# @param log_level [Symbol] the log level to use for logging requests (default: :info)
#
# Returns a JSON parseable log entry like:
# [INFO] [RequestLogger] {"method":"GET","path":"/samples/1234","format":"html","status_code":200,
#   "status_message":"OK","duration_ms":935,"client_ip":"172.21.43.210",
#   "request_id":"9fd18098-dea3-46f0-83c8-c41852441db3","@timestamp":"2026-02-12T12:10:50.284+00:00"}
class RequestLogger
  def initialize(app, log_level: :info)
    @app = app
    @log_level = log_level
  end

  def call(env)
    response, elapsed_ms = elapsed_milliseconds { @app.call(env) }

    request = ActionDispatch::Request.new(env)
    log_request(request, response, elapsed_ms)

    response
  end

  private

  # Get the current clock time using the Rack::Runtime clock
  def clock_time
    Rack::Utils.clock_time
  end

  def elapsed_milliseconds
    start_time = clock_time
    result = yield
    end_time = clock_time

    elapsed_ms = ((end_time - start_time) * 1000).round
    [result, elapsed_ms]
  end

  def log_request(request, response, elapsed_ms)
    status_code, _headers, _body = response

    status_message = Rack::Utils::HTTP_STATUS_CODES[status_code] || 'Unknown Status'
    timestamp = Time.zone.now.iso8601(3)

    record = {
      method: request.request_method,
      path: request.fullpath,
      format: request.format.symbol,
      status_code: status_code,
      status_message: status_message,
      duration_ms: elapsed_ms,
      client_ip: request.remote_ip,
      request_id: request.request_id,
      '@timestamp': timestamp
    }

    Rails.logger.public_send(@log_level, "[RequestLogger] #{record.to_json}")
  end
end
