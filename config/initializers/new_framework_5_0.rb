# frozen_string_literal: true

Rails.application.configure do
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: %i[get post options patch], credentials: false
    end
  end
end
