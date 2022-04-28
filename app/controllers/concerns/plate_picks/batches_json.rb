# frozen_string_literal: true
module PlatePicks
  # Translate the pick information into a format more useful for plate picks
  class BatchesJson
    def initialize(batch_id, pick_information, plate_information)
      @batch_id = batch_id
      @pick_information = pick_information
      @plate_information = plate_information
    end

    def to_json(_ = nil)
      { batch: { id: @batch_id.to_s, picks: picks } }
    end

    private

    def picks
      @pick_information.flat_map do |destination_plate, plate_pick_info|
        total_picks = plate_pick_info.length
        plate_pick_info.map do |pick_name, pick_plates|
          {
            name: "#{@batch_id}:#{destination_plate} #{pick_name} of #{total_picks}",
            plates: pick_plates[1].each_key.map { |barcode| @plate_information[barcode] }
          }
        end
      end
    end
  end
end
