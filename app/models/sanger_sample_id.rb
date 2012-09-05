class SangerSampleId < ActiveRecord::Base
  class Factory
    def self.instance
      @instance ||= self.new
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
