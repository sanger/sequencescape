# frozen_string_literal: true

class TaxaController < ApplicationController
  skip_before_action :login_required # there's no sensitive information here

  def index
    return render plain: 'Missing required parameter: term', status: :bad_request if params[:term].blank?

    # Lookup by term and render results
    term = params[:term].parameterize.underscore
    url = "#{configatron.taxon_lookup_url}/esearch.fcgi"
    params = { db: 'taxonomy', term: term }

    result = perform_lookup(url, params)

    render plain: result
  rescue Faraday::Error
    head :bad_gateway
  end

  def show
    # params[:id] is the taxon ID
    # Lookup and render the taxon
    id = params[:id]
    url = "#{configatron.taxon_lookup_url}/efetch.fcgi"
    params = { db: 'taxonomy', mode: 'xml', id: id }

    result = perform_lookup(url, params)

    render plain: result
  rescue Faraday::Error
    head :bad_gateway
  end

  private

  def headers
    {
      'User-Agent' => 'Internet Explorer 5.0' # Is this still required in 2025?
    }
  end

  def proxy
    return nil if configatron.disable_web_proxy == true
    return configatron.proxy if configatron.fetch(:proxy).present?
    return ENV['http_proxy'] if ENV['http_proxy'].present?

    nil
  end

  def perform_lookup(url, params = {})
    conn = Faraday.new(url:, params:, headers:, proxy:) do |builder|
      # Raises an error on 4xx and 5xx responses.
      builder.response :raise_error
    end

    response = conn.get

    response.body
  end
end
