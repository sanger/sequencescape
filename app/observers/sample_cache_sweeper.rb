class SampleCacheSweeper < ActiveRecord::Observer
  include XmlCacheHelper
  observe Sample, Sample::Metadata, StudySample, Study, ReferenceGenome, Aliquot, Aliquot::Receptacle
  set_caching_for_controller 'samples'
  set_caching_for_model 'samples'

  THROUGH_JOINS = {
    'study' => [
      "INNER JOIN study_samples ON study_samples.sample_id=samples.id",
      "INNER JOIN studies ON study_samples.study_id=studies.id"
    ],
    'receptacle' => [
      "INNER JOIN aliquots ON aliquots.sample_id=samples.id",
      "INNER JOIN assets ON aliquots.receptacle_id=assets.id"
    ]
  }

  def through(model, distance = nil)
    joins = THROUGH_JOINS[model]
    joins.slice(0, distance || joins.size)
  end
  private :through

  def joins_for(record)
    return [] if record.is_a?(Sample)
    case
    when record.is_a?(Sample::Metadata)    then metadata
    when record.is_a?(StudySample)         then through('study', 1)
    when record.is_a?(Study)               then through('study')
    when record.is_a?(Aliquot)             then through('receptacle', 1)
    when record.is_a?(Aliquot::Receptacle) then through('receptacle')
    when record.is_a?(ReferenceGenome)     then metadata_association(:reference_genome)
    end
  end
  private :joins_for
end
