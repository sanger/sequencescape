# frozen_string_literal: true
module StudyReport::WellDetails # rubocop:todo Style/Documentation
  def self.included(base)
    base.class_eval do
      scope :for_study_report,
            -> {
              includes(
                [
                  :map,
                  :well_attribute,
                  :events,
                  {
                    plate: %i[plate_purpose events barcodes],
                    primary_aliquot: {
                      sample: [:sample_metadata, { sample_manifest: :supplier }]
                    }
                  }
                ]
              )
            }
    end
  end

  # def genotyping_status
  #   primary_aliquot.present? ? primary_aliquot.sample.genotyping_done : ''
  # end

  def qc_report # rubocop:todo Metrics/AbcSize
    # well must be from a stock plate
    return {} unless plate.try(:stock_plate?)

    qc_data = super
    qc_data.merge!(
      well: map.description,
      concentration: well_attribute.concentration,
      sequenom_count: "#{get_sequenom_count.to_i}/30",
      sequenom_gender: get_gender_markers,
      pico: well_attribute.pico_pass,
      is_in_fluidigm: fluidigm_stamp_date,
      gel: well_attribute.gel_pass,
      plate_barcode: plate.barcode_for_study_report,
      measured_volume: well_attribute.measured_volume,
      current_volume: well_attribute.current_volume,
      gel_qc_date: gel_qc_date,
      pico_date: pico_date,
      qc_started_date: plate.qc_started_date,
      sequenom_stamp_date: plate.sequenom_stamp_date,
      quantity: well_attribute.quantity_in_micro_grams.try(:round, 3),
      initial_volume: well_attribute.initial_volume
    )
    qc_data
  end
end
