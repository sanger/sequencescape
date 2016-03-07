#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
module ModelExtensions::Well
  def self.included(base)
    base.class_eval do
      scope :for_api_plate_json, -> { includes(
              :map,
              :transfer_requests, # Should be :transfer_requests_as_target
              :uuid_object, {
                :plate => :uuid_object,
                :aliquots => [
                  :bait_library, {
                    :tag => :tag_group,
                    :sample => [
                      :uuid_object, {
                        :primary_study   => { :study_metadata => :reference_genome },
                        :sample_metadata => :reference_genome
                      }
                    ]
                  }
                ]
              }
            )
    }
    end
  end
end
