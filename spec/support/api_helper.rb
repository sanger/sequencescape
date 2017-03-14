module ApiHelper
  def api_request(action, path, body = nil)
    headers = {
      'HTTP_ACCEPT' => 'application/json'
    }
    headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
    headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = authorised_app.key
    yield(headers) if block_given?
    send(action.downcase, path, body, headers)
  end

  def unauthorized_api_request(action, path, body = nil)
    headers = {
      'HTTP_ACCEPT' => 'application/json'
    }
    headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
    yield(headers) if block_given?
    send(action.downcase, path, body, headers)
  end

  def user_api_request(user, action, path, body = nil)
    headers = {
      'HTTP_ACCEPT' => 'application/json'
    }
    cookies['api_key'] = user.api_key
    headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
    yield(headers) if block_given?
    send(action.downcase, path, body, headers)
  end
end
