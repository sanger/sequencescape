# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
module ActiveResource::Formats::PacBioJsonFormat
  class << self
    def decode(json)
      ActiveSupport::JSON.decode(json)['Rows']
    end

    def extension
      'json'
    end

    def encode(hash, options = nil)
      ActiveSupport::JSON.encode(hash, options)
    end

    def mime_type
      'application/json'
    end
  end
end
