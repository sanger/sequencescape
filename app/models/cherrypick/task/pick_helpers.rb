module Cherrypick::Task::PickHelpers
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickByNanoGramsPerMicroLitre
      include Cherrypick::Task::PickByNanoGrams
      include Cherrypick::Task::PickByMicroLitre
    end
  end

  def cherrypick_wells_grouped_by_submission(requests, purpose, &picker)
    purpose.cherrypick_strategy.pick(requests, OpenStruct.new(:max_beds => 1000)).map do |wells|
      wells_and_requests = wells.zip(purpose.well_locations.slice(0, wells.size)).map do |request, position|
        if request.present?
          well     = request.target_asset
          well.map = position
          picker.call(well, request)
          [ well, request ]
        else
          nil
        end
      end.compact

      wells_and_requests.each { |well, request| well.well_attribute.save! ; well.save! ; request.pass! }
      purpose.create!(:do_not_create_wells) do |plate|
        plate.name = "Cherrypicked #{plate.barcode}"
      end.tap do |plate|
        plate.wells.attach(wells_and_requests.map(&:first))
      end
    end
  end
  private :cherrypick_wells_grouped_by_submission

  def valid_float_param?(input_value)  
    !input_value.blank? && (input_value.to_f > 0.0)
  end 
  private :valid_float_param?
end
