# frozen_string_literal: true

module ApiV2Helper
  DEFAULT_HEADERS = { 'ACCEPT' => 'application/vnd.api+json', 'CONTENT_TYPE' => 'application/vnd.api+json' }.freeze

  def api_get(path, headers: {})
    headers.merge!(DEFAULT_HEADERS)
    get(path, headers: headers)
  end

  def api_patch(path, payload, headers: {})
    headers.merge!(DEFAULT_HEADERS)
    patch(path, params: payload.to_json, headers: headers)
  end

  def api_post(path, payload, headers: {})
    headers.merge!(DEFAULT_HEADERS)
    post(path, params: payload.to_json, headers: headers)
  end

  def json
    JSON.parse(response.body)
  end
end
