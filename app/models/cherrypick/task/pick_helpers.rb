module Cherrypick::Task::PickHelpers
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickByNanoGramsPerMicroLitre
      include Cherrypick::Task::PickByNanoGrams
      include Cherrypick::Task::PickByMicroLitre
    end
  end

  def cherrypick_wells_grouped_by_submission(requests, plate, &picker)
    sorted_requests = sort_grouped_requests_by_submission_id(requests)
    positions       = Map.where_plate_size(plate.size).send("in_#{plate.plate_purpose.cherrypick_direction}_major_order").slice(0, sorted_requests.size)

    wells_and_requests = sorted_requests.zip(positions).map do |request, position|
      well     = request.target_asset
      well.map = position
      picker.call(well, request)
      [ well, request ]
    end

    wells_and_requests.each { |well, request| well.well_attribute.save! ; well.save! ; request.pass! }
    plate.wells.attach(wells_and_requests.map(&:first))
  end
  private :cherrypick_wells_grouped_by_submission

  def valid_float_param?(input_value)  
    !input_value.blank? && (input_value.to_f > 0.0)
  end 
  private :valid_float_param?
end
