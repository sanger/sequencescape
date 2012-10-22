
# Pre_PCR plates will remain 'started; until the run is complete.

class Search::FindOutstandingIlluminaBPrePcrPlates < Search
  def scope(criteria)
    Plate.include_plate_metadata.include_plate_purpose.with_plate_purpose(pre_pcr_plate_purpose).in_state(['pending','started'])
  end

  def self.pre_pcr_plate_purpose
    @shearing_plate_purpose ||= PlatePurpose.find_by_name('ILB_STD_PREPCR')
  end
  delegate :pre_pcr_plate_purpose, :to => 'self.class'

end
