module Cherrypick::Task::PickHelpers
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickByNanoGramsPerMicroLitre
      include Cherrypick::Task::PickByNanoGrams
      include Cherrypick::Task::PickByMicroLitre
    end
  end

  def cherrypick_wells_grouped_by_submission(requests, plate, &picker)
    wells_and_requests = sort_grouped_requests_by_submission_id(requests).each_with_index.map do |request, index|
      well     = request.target_asset
      well.map = Map.where_plate_size(plate.size).where_vertical_plate_position(index+1).first
      picker.call(well, request)
      [ well, request ]
    end

    wells_and_requests.each { |well, request| well.well_attribute.save! ; well.save! ; request.pass! }
    plate.wells.attach(wells_and_requests.map(&:first))
  end
  private :cherrypick_wells_grouped_by_submission

  def create_nano_grams_per_micro_litre_picker(params)
    volume, concentration = params[:volume_required].to_f, params[:concentration_required].to_f
    lambda do |well, request|
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(volume, concentration, request.asset.get_concentration)
    end
  end
  private :create_nano_grams_per_micro_litre_picker

  def create_nano_grams_picker(params)
    min_vol, max_vol, nano_grams = params[:minimum_volume].to_f, params[:maximum_volume].to_f, params[:total_nano_grams].to_f
    lambda do |well, request|
      well.volume_to_cherrypick_by_nano_grams(min_vol, max_vol, nano_grams, request.asset)
    end
  end
  private :create_nano_grams_picker

  def create_micro_litre_picker(params)
    volume = params[:micro_litre_volume_required].to_f
    lambda do |well, _|
      well.volume_to_cherrypick_by_micro_litre(volume)
    end
  end
  private :create_micro_litre_picker
end
