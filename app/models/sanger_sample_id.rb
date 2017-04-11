# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class SangerSampleId < ActiveRecord::Base
  class Factory
    def self.instance
      @instance ||= new
    end

    def next!
      SangerSampleId.create!.sample_id
    end
  end

  alias_method(:sample_id, :id)

  class << self
    def generate_sanger_sample_id!(study_abbreviation, sanger_id = nil)
      "#{study_abbreviation}#{sanger_id || SangerSampleId::Factory.instance.next!}"
    end
  end
end
