# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

module ModelExtensions::Well
  def self.included(base)
    base.class_eval do
      scope :for_api_plate_json, -> { preload(
              :map,
              :transfer_requests, # Should be :transfer_requests_as_target
                              # :uuid_object is included elsewhere, and trying to also include it here
                              # actually disrupts the eager loading.
                              plate: :uuid_object,
                              aliquots: [
                                :bait_library, {
                    tag: :tag_group,
                    sample: [
                      :study_reference_genome,
                      :uuid_object, {
                        sample_metadata: :reference_genome
                      }
                    ]
                  }
                              ]
            )
                                 }
    end
  end
end
