module ModelExtensions::Plate
  module NamedScopeHelpers
    def include_plate_named_scope(plate_association)
      named_scope :"include_#{plate_association}", {
        :include => { plate_association.to_sym => ::ModelExtensions::Plate::PLATE_INCLUDES }
      }
    end
  end

  PLATE_INCLUDES = [
    :plate_metadata, {
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
  ]

  def self.included(base)
    base.class_eval do
      named_scope :include_plate_purpose, :include => :plate_purpose
      named_scope :include_wells_with_aliquots, :include => ::ModelExtensions::Plate::PLATE_INCLUDES
    end
  end

  def plate_purpose_or_stock_plate
    self.plate_purpose || PlatePurpose.find_by_name('Stock Plate')
  end
end
