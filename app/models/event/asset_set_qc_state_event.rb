# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Event::AssetSetQcStateEvent < Event
  class << self
    def self.constructor_for_event_type(type)
      define_method(:"create_#{ type }!") do |asset, reason|
        create!(
          eventful: asset,
          family: 'update',
          content: reason,
          message: reason
        )
      end
    end

    constructor_for_event_type('passed')
    constructor_for_event_type('failed')
  end
end
