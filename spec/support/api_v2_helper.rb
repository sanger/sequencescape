module ApiV2Helper
  DEFAULT_HEADERS = {
    'ACCEPT' => 'application/vnd.api+json',
    'CONTENT_TYPE' => 'application/vnd.api+json'
  }.freeze

  def api_get(path, headers: {})
    headers.merge!(DEFAULT_HEADERS)
    get(path, headers)
  end

  def api_patch(path, payload, headers: {})
    headers.merge!(DEFAULT_HEADERS)
    patch(path, payload.to_json, headers)
  end

  def json
    JSON.parse(response.body)
  end
end
