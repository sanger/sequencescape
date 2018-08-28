
class PicoAssayPlate < Plate
  class WellDetail
    attr_accessor :map, :parent_plate, :qc_assay

    def initialize(details, parent_plate, qc_assay)
      @map = details[:map]
      @concentration = details[:concentration]
      @parent_plate = parent_plate
      @qc_assay = qc_assay
    end

    def target_map
      Map.find_by(description: map, asset_size: parent_plate.stock_plate.size)
    end

    def target_well
      @target_well ||= parent_plate.stock_plate.wells.find_by(map_id: target_map.id)
    end

    def concentration
      @concentration > 0 ? @concentration : 0.0
    end

    # TODO: this method needs to go, to be replace by direct calls
    # to #grade_as_passed and #grade_as_failed
    def grade_as!(state)
      case state
      when 'passed' then grade_as_passed
      when 'failed' then grade_as_failed
      end

      update_well_concentration!
    end

    def grade_as_passed
      target_well.events.create_pico!('Pass')
      target_well.well_attribute.pass_pico_test
    end

    def grade_as_failed
      target_well.events.create_pico!('Fail')
      target_well.well_attribute.fail_pico_test
    end

    def update_well_concentration!
      QcResult.create!(asset: target_well, qc_assay: qc_assay, key: 'concentration', value: concentration, units: 'ng/ul', assay_type: 'PicoGreen', assay_version: 'v0.1')
    end
  end

  def upload_pico_results(state, failure_reason, well_details)
    qc_assay = QcAssay.new
    return false if state.nil? || well_details.blank? || stock_plate.nil?

    ActiveRecord::Base.transaction do
      event = stock_plate.events.create_pico!(state)
      # Adds a failure reason if it is available.
      event.update_attributes(descriptor_key: failure_reason) unless failure_reason.nil?
      well_details.each { |details| WellDetail.new(details[:well], self, qc_assay).grade_as!(state) }
    end
  end
end
