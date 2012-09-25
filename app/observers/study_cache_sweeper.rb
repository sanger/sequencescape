class StudyCacheSweeper < ActiveRecord::Observer
  include XmlCacheHelper
  observe Study, Study::Metadata, StudyType, DataReleaseStudyType, ReferenceGenome, FacultySponsor
  set_caching_for_controller 'studies'
  set_caching_for_model 'studies'

  # Determines the JOINs necessary to identify any studies that are affected by the record change.  Note
  # that once you get a Study::Metadata record you always need to include that table, but the others do
  # not go through each other (like the BatchCacheSweeper does).
  def query_details_for(record, &block)
    case
    when record.is_a?(Study)                then yield([], query_conditions_for(record))
    when record.is_a?(Study::Metadata)      then metadata(record, &block)
    when record.is_a?(StudyType)            then metadata_association(:study_type, record, &block)
    when record.is_a?(DataReleaseStudyType) then metadata_association(:data_release_study_type, record, &block)
    when record.is_a?(ReferenceGenome)      then metadata_association(:reference_genome, record, &block)
    when record.is_a?(FacultySponsor)       then metadata_association(:faculty_sponsor, record, &block)
    end
  end
  private :query_details_for
end
