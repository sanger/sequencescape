# frozen_string_literal: true

# Log requests and their responses for monitoring.
#
# Ideally we would like this to produce an output that contains the following information:
# {
#   "method":"GET",
#   "path":"/",
#   "format":"html",
#   "controller":"homes",
#   "action":"show",
#   "status":200,
#   "duration":467.41,
#   "view":383.75,
#   "db":165.11,
#   "ip":"::1",
#   "route":"homes#show",
#   "request_id":"ceede35e-0a35-4d6b-b7bc-735ff8daa91f",
#   "source":"127.0.0.1",
#   "tags":["request"],
#   "@timestamp":"2026-02-14T14:38:54.264Z",
#   "@version":"1"
# }
class RequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    response, elapsed_ms = elapsed_milliseconds { @app.call(env) }

    request = ActionDispatch::Request.new(env)
    # debug(request, response)
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
      status_code: status_code,
      status_message: status_message,
      duration_ms: elapsed_ms,
      client_ip: request.remote_ip,
      request_id: request.request_id,
      '@timestamp': timestamp
    }
    Rails.logger.info("[RequestLogger] #{record.to_json}")
  end

  def debug(request, response)
    _status_code, headers, _body = response

    puts 'Request:'
    pp (request.methods - Object.methods).sort
    puts '-------'
    puts "Request env: #{request.env.inspect}"
    puts '-------'
    puts "Response: #{headers.inspect}"
    puts '-------'
  end
end
