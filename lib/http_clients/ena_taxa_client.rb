# frozen_string_literal: true

require 'faraday'

# Retrieves taxonomic information from the ENA taxonomy database.
#
# Usage:
#   client = HTTPClients::ENATaxaClient.new
#   client.id_from_text('human') # returns 9606
#   client.name_from_id(9606) # returns 'homo sapiens'
class HTTPClients::ENATaxaClient < HTTPClient
  # Make Faraday connection injectable for easier testing.
  def initialize(conn = nil)
    super(conn || Faraday.new(
      url: configatron.ena_taxon_lookup_url,
      headers: default_headers,
      proxy: proxy
    ) do |f|
      f.response :json
    end)
  end

  def id_from_text(suggestion)
    # Returns the ENA taxon ID for a given organism suggestion string.
    #
    # @param suggestion [String] The organism name or suggestion (eg: 'human')
    # @return [Integer] The ENA taxon ID (eg: 9606)
    response = @conn.get("suggest-for-submission/#{suggestion}")
    first_taxon = response.body.first
    first_taxon['taxId'].to_i if first_taxon
  end

  def name_from_id(id)
    # Returns the common name for a given ENA taxon ID.
    #
    # @param id [Integer, String] The ENA taxon ID (eg: 9606)
    # @return [String] The common name (eg: 'homo sapiens')
    response = @conn.get("tax-id/#{id}")
    response.body['commonName'] || response.body['scientificName']
  end
end
