# frozen_string_literal: true

require 'faraday'

# Retrieves taxonomic information from NCBI's Taxonomy database.
#
# Usage:
# Usage:
#   client = NCBITaxaClient.new
#   client.id_from_text('human') # returns 9606
#   client.name_from_id(9606) # returns 'homo sapiens'
class HTTPClients::NCBITaxaClient < HTTPClient
  # Make Faraday connection injectable for easier testing.
  def initialize(conn = nil)
    super(conn || Faraday.new(
      url: configatron.taxon_lookup_url,
      headers: default_headers,
      proxy: proxy
    ))
  end

  def id_from_text(term)
    response = @conn.get('/esearch.fcgi', { db: 'taxonomy', term: term })
    response.body
  end

  def name_from_id(taxon_id)
    response = @conn.get('/efetch.fcgi', { db: 'taxonomy', mode: 'xml', id: taxon_id })
    response.body
  end
end
