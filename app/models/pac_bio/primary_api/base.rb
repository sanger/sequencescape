require 'pac_bio_json_format'
class PacBio::PrimaryApi::Base < ActiveResource::Base
  self.site = configatron.pac_bio_instrument_api
  self.format = :pac_bio_json
  self.proxy = configatron.proxy if configatron.proxy

  def self.collection_path(*args, &block)
    super.sub(/\.json/, '')
  end

end


