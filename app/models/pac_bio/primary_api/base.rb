#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
require 'pac_bio_json_format'
class PacBio::PrimaryApi::Base < ActiveResource::Base
  self.site = configatron.pac_bio_instrument_api.to_s
  self.format = :pac_bio_json
  self.proxy = configatron.proxy.to_s if configatron.proxy

  def self.collection_path(*args, &block)
    super.sub(/\.json/, '')
  end

end


