# Pre_PCR plates will remain 'started; until the run is complete.
# Handled finding of plates for the defunct Illumina-B pipelines
# Can be deprecated.
class Search::FindOutstandingIlluminaBPrePcrPlates < Search
  def scope(_criteria)
    Plate.include_plate_metadata.include_plate_purpose.with_purpose(pre_pcr_plate_purpose).in_state(%w[pending started])
  end

  def self.pre_pcr_plate_purpose
    PlatePurpose.find_by(name: 'ILB_STD_PREPCR')
  end
  delegate :pre_pcr_plate_purpose, to: 'self.class'
end
