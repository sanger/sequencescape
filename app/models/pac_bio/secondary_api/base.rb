require 'pac_bio_json_format'
class PacBio::SecondaryApi::Base < ActiveResource::Base
  self.site = configatron.pac_bio_smrt_portal_api
  self.format = :pac_bio_json
  self.proxy = configatron.proxy if configatron.proxy

  def self.collection_path(*args, &block)
    super.sub(/\.json/, '')
  end
end


