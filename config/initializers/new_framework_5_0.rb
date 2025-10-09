# frozen_string_literal: true

# Configure the default encoding used in templates for Ruby 1.9.
config.encoding = 'utf-8'

# Default options which predate the Rails 5 switch
config.active_record.belongs_to_required_by_default = false
config.action_controller.forgery_protection_origin_check = false
config.action_controller.per_form_csrf_tokens = false

# Rails 5

config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: %i[get post options patch], credentials: false
  end
end

# end Rails 5 #
