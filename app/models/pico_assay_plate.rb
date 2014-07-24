class PicoAssayPlate < Plate
  self.prefix = "PA"

  class WellDetail
    attr_accessor :map, :concentration, :parent_plate

    def initialize(details, parent_plate)
      @map = details[:map]
      @concentration = details[:concentration]
      @parent_plate = parent_plate
    end

    def target_map
      Map.find_by_description_and_asset_size(map, parent_plate.stock_plate.size)
    end

    def target_well
      @target_well ||= parent_plate.stock_plate.wells.find_by_map_id(target_map.id)
    end

    # TODO this method needs to go, to be replace by direct calls
    # to #grade_as_passed and #grade_as_failed
    def grade_as!(state)
      case state
      when "passed" then grade_as_passed
      when "failed" then grade_as_failed
      end

      update_well_concentraion!
    end

    def grade_as_passed
      target_well.events.create_pico!('Pass')
      target_well.well_attribute.pass_pico_test
    end

    def grade_as_failed
      target_well.events.create_pico!('Fail')
      target_well.well_attribute.fail_pico_test
    end

    def update_well_concentraion!
      target_well.set_concentration(concentration)
    end
  end


  def upload_pico_results(state, well_details)
    return false if state.nil? || well_details.blank? || stock_plate().nil?

    ActiveRecord::Base.transaction do
      stock_plate.events.create_pico!(state)
      well_details.each { |details| WellDetail.new(details[:well], self).grade_as!(state) }
    end
  end

end
