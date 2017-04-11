# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015,2016 Genome Research Ltd.

class SampleCacheSweeper < ActiveRecord::Observer
  include XmlCacheHelper
  observe Sample, Sample::Metadata, StudySample, ReferenceGenome, Aliquot, Aliquot::Receptacle
  set_caching_for_controller 'samples'
  set_caching_for_model 'samples'

  THROUGH_JOINS = {
    'study'      => 'INNER JOIN study_samples ON study_samples.sample_id=samples.id',
    'receptacle' => 'INNER JOIN aliquots ON aliquots.sample_id=samples.id'
  }

  # We shorten the query conditions for studies and receptacles because we do not need to perform
  # a JOIN against their table, considering we go through a JOIN table anyway.
  def through(record)
    model, conditions =
      case
      when record.is_a?(StudySample)         then ['study',      query_conditions_for(record)]
      when record.is_a?(Aliquot)             then ['receptacle', query_conditions_for(record)]
      when record.is_a?(Aliquot::Receptacle) then ['receptacle', "aliquots.receptacle_id=#{record.id}"]
      end
    yield(Array(THROUGH_JOINS[model]), conditions)
  end
  private :through

  def query_details_for(record, &block)
    case
    when record.is_a?(Sample)           then yield([], query_conditions_for(record))
    when record.is_a?(Sample::Metadata) then metadata(record, &block)
    when record.is_a?(ReferenceGenome)  then metadata_association(:reference_genome, record, &block)
    else through(record, &block)
    end
  end
  private :query_details_for
end
