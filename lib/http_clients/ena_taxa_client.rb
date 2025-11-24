# frozen_string_literal: true

require 'faraday'

module HTTPClients
  # Retrieves taxonomic information from the ENA taxonomy database.
  #
  # Usage:
  #   ```rb
  #   client = HTTPClients::ENATaxaClient.new
  #   client.id_from_text('human') # returns 9606
  #   client.name_from_id(9606) # returns 'homo sapiens'
  #   ````
  #
  # API usage guide: https://ena-docs.readthedocs.io/en/latest/retrieval/programmatic-access/taxon-based-search.html
  # Swagger docs: https://www.ebi.ac.uk/ena/taxonomy/rest/swagger-ui/index.html
  class ENATaxaClient < BaseClient
    def conn
      @conn ||= Faraday.new(
        url: configatron.ena_taxon_lookup_url,
        headers: default_headers,
        proxy: proxy
      ) do |f|
        f.response :json
      end
    end

    # Returns the ENA taxon information for a given organism suggestion string.
    #
    #
    # @param suggestion [String] The organism name or suggestion (e.g., 'human')
    # @return [Hash, nil] A hash with 'taxId', 'scientificName', and 'commonName' if found, or nil if not found.
    def taxon_from_text(suggestion)
      suggestion = ERB::Util.url_encode(suggestion)
      response = conn.get("any-name/#{suggestion}")
      first_taxon = response.body.first
      return unless first_taxon

      # extract relevant fields and return as a hash
      {
        'taxId' => first_taxon['taxId'],
        'scientificName' => first_taxon['scientificName'],
        'commonName' => first_taxon['commonName'],
        'submittable' => first_taxon['submittable']
      }
    end

    # Returns the taxon information for a given ENA taxon ID.
    #
    # @param id [Integer, String] The ENA taxon ID (eg: 9606)
    # @return [Hash] A hash with 'taxId', 'scientificName', and 'commonName'.
    def taxon_from_id(id)
      response = conn.get("tax-id/#{id}")
      results = response.body

      # extract taxId, scientificName, commonName from the results and return as a hash
      {
        'taxId' => results['taxId'],
        'scientificName' => results['scientificName'],
        'commonName' => results['commonName']
      }
    end
  end
end
