# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

module Cherrypick::Task::PickHelpers
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickByNanoGramsPerMicroLitre
      include Cherrypick::Task::PickByNanoGrams
      include Cherrypick::Task::PickByMicroLitre
    end
  end

  def cherrypick_wells_grouped_by_submission(requests, robot, purpose)
    plate, purpose = nil, purpose
    plate, purpose = purpose, purpose.plate_purpose if purpose.is_a?(Plate)

    purpose.cherrypick_strategy.pick(requests, robot, plate).map do |wells|
      wells_and_requests = wells.zip(purpose.well_locations.slice(0, wells.size)).map do |request, position|
        if request.present?
          well     = request.target_asset
          well.map = position
          yield(well, request)
          [well, request]
        else
          nil
        end
      end.compact

      wells_and_requests.each { |well, request| well.well_attribute.save!; well.save!; request.pass! }

      # Attach the wells to the existing partial plate, or to a new plate if we need to create
      # one.  After the partial plate has been attached to we automatically need a new plate.
      plate ||= purpose.create!(:do_not_create_wells) do |plate|
        plate.name = "Cherrypicked #{plate.barcode}"
      end
      plate.tap do |working_on|
        working_on.wells << wells_and_requests.map(&:first)
        plate = nil
      end
    end
  end
  private :cherrypick_wells_grouped_by_submission

  def valid_float_param?(input_value)
    !input_value.blank? && (input_value.to_f > 0.0)
  end
  private :valid_float_param?
end
