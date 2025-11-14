# frozen_string_literal: true

class TaxaController < ApplicationController
  skip_before_action :login_required # there's no sensitive information here

  def index
    return render plain: 'Missing required parameter: term', status: :bad_request if params[:term].blank?

    # Lookup by term and render results
    term = params[:term]
    taxon = client.taxon_from_text(term)

    return head :not_found if taxon.nil?

    render json: taxon
  rescue Faraday::Error
    head :bad_gateway
  end

  def show
    # Lookup by id and render the taxon
    id = params[:id] # the given taxon ID
    taxon = client.taxon_from_id(id)

    return head :not_found if taxon['taxId'].nil?

    render json: taxon
  rescue Faraday::Error
    head :bad_gateway
  end

  private

  def client
    @client ||= HTTPClients::ENATaxaClient.new
  end
end
