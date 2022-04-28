# frozen_string_literal: true
# By default Rails metal applications can return 404 to say that they don't handle the request.
# However, we use 404 in the API to indicate that we have handled the request but the resource
# does not exist.  So here we monkeypatch Rails so that if the 404 response has a body then we
# can return that.
class Rails::Rack::Metal
  def call(env)
    @metals.keys.each do |app|
      result = app.call(env)
      return result unless (result[0].to_i == 404) && result[2].blank?
    end
    @app.call(env)
  end
end
