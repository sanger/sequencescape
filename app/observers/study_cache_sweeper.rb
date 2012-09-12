class StudyCacheSweeper < ActiveRecord::Observer
  include XmlCacheHelper
  observe Study, Study::Metadata, StudyType, DataReleaseStudyType, ReferenceGenome, FacultySponsor
  set_caching_for_controller 'studies'
  set_caching_for_model 'studies'

  # Determines the JOINs necessary to identify any studies that are affected by the record change.  Note
  # that once you get a Study::Metadata record you always need to include that table, but the others do
  # not go through each other (like the BatchCacheSweeper does).
  def joins_for(record)
    return [] if record.is_a?(Study)
    case
    when record.is_a?(Study::Metadata)      then metadata
    when record.is_a?(StudyType)            then metadata_reference(:study_type)
    when record.is_a?(DataReleaseStudyType) then metadata_reference(:data_release_study_type)
    when record.is_a?(ReferenceGenome)      then metadata_reference(:reference_genome)
    when record.is_a?(FacultySponsor)       then metadata_reference(:faculty_sponsor)
    else nil
    end
  end
  private :joins_for
end
