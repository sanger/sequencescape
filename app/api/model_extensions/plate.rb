module ModelExtensions::Plate
  def self.included(base)
    base.class_eval do
      named_scope :include_plate_purpose, :include => :plate_purpose
      named_scope :include_wells_with_aliquots, :include => {
        :wells => [
          :map,
          :uuid_object, {
            :aliquots => [
              :tag,
              :bait_library, {
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
      }
    end
  end

  def plate_purpose_or_stock_plate
    self.plate_purpose || PlatePurpose.find_by_name('Stock Plate')
  end
end
