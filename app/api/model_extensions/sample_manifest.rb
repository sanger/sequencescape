#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
module ModelExtensions::SampleManifest
  def self.included(base)
    base.class_eval do
      named_scope :include_samples, {
        :include => {
          :samples => [
            :uuid_object, {
              :sample_metadata => :reference_genome,
              :primary_study   => { :study_metadata => :reference_genome }
            }
          ]
        }
      }
      delegate :io_samples, :to => :core_behaviour
    end
  end
end
