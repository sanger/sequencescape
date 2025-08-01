# frozen_string_literal: true

# Created from the tutorial at https://www.mintbit.com/blog/custom-404-500-error-pages-in-rails/

class ErrorsController < ApplicationController
  skip_before_action :login_required

  layout false

  def not_found
    render status: :not_found # 404 Not Found
  end

  # TODO: Implement the `unacceptable` method to handle 406 Not Acceptable errors

  # TODO: Implement the `unprocessable` method to handle 422 Unprocessable Entity errors

  def internal_server
    render status: :internal_server_error # 500 Internal Server Error
  end

  def service_unavailable
    render status: :service_unavailable # 503 Service Unavailable
  end
end
