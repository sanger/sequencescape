module ModelExtensions::Well
  def self.included(base)
    base.class_eval do
      named_scope :for_api_plate_json, :include => [
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
      ]
    end
  end
end
