# frozen_string_literal: true
class SangerSampleId < ApplicationRecord
  class Factory
    def self.instance
      @instance ||= new
    end

    def next!
      SangerSampleId.create!.sample_id
    end
  end

  alias sample_id id

  class << self
    def generate_sanger_sample_id!(study_abbreviation, sanger_id = nil)
      "#{study_abbreviation}#{sanger_id || SangerSampleId::Factory.instance.next!}"
    end
  end
end
