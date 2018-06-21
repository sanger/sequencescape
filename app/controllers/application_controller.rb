
require 'exceptions'
require 'authenticated_system'

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => "4418f0a814148fc28a0a38971e433b7d"

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  # filter_parameter_logging :password

  # Provide authentication, and "remember me"
  include AuthenticatedSystem
  before_action :login_required
  before_action :extract_header_info

  # clean parameters hash from :check generated by checktext_field fields.
  def clean_params_from_check(object)
    return object unless object.is_a?(Hash)
    new_hash = object.class.new
    to_nil = []
    object.each do |k, v|
      if k == 'check' and v.is_a?(Hash)
        v.each do |k, v|
          to_nil << k unless v == 'true'
        end
      else # normal
        new_hash[k] = clean_params_from_check(v)
      end
    end

    to_nil.each do |k|
      new_hash[k] = nil
    end

    new_hash
  end

  public

  def block_api_access(message = nil, format = :xml)
    content = { error: 'Unsupported API access' }
    content[:message] = message unless message.nil?
    { format => content.send("to_#{format}".to_sym, root: :errors), :status => 406 }
  end

  def extract_header_info
    exclude_nested_resource = request.headers['HTTP_EXCLUDE_NESTED_RESOURCE'] || params[:exclude_nested_resource]
    @exclude_nested_resource = exclude_nested_resource && exclude_nested_resource.to_s.casecmp('true').zero?
  end

  def set_cache_disabled!
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = 'Fri, 01 Jan 1990 00:00:00 GMT'
  end

  def evil_parameter_hack!
    # WARNING! This hack is purely in place while we manually update ALL our
    # existing controllers to support Strong Parameters. It should under
    # not circumstances get used in new code, and should be removed from
    # existing controllers as soon as humanly possible.
    params.permit!
  end
end
