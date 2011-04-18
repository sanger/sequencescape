class SangerSampleId < ActiveRecord::Base
  alias_method(:sample_id, :id)

  def self.generate_sanger_sample_id!(study_abbreviation, sanger_id = nil)
    sanger_id ||= SangerSampleId.create!.sample_id
    "#{study_abbreviation}#{sanger_id}"
  end
end
