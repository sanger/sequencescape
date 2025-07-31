# frozen_string_literal: true

# Created from the tutorial at https://www.mintbit.com/blog/custom-404-500-error-pages-in-rails/

class ErrorsController < ApplicationController
  skip_before_action :login_required

  layout false

  def not_found
    render status: :not_found # 404 Not Found
  end

  #  def unacceptable
  #    render status: :not_acceptable # 406 Not Acceptable
  #  end

  #  def unprocessable
  #    render status: :unprocessable_content # 422 Unprocessable Entity
  #  end

  def internal_server
    render status: :internal_server_error # 500 Internal Server Error
  end

  def service_unavailable
    render status: :service_unavailable # 503 Service Unavailable
  end
end
