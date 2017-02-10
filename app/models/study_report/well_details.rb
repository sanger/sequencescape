# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

module StudyReport::WellDetails
  def self.included(base)
    base.class_eval do
      scope :for_study_report, -> { includes([
        :map,
        :well_attribute,
        :events,
        { plate: [:plate_purpose, :events], primary_aliquot: { sample: [:sample_metadata, { sample_manifest: :supplier }, :external_properties] } },
        { latest_child_well: [:map, { plate: [:plate_purpose, :plate_metadata] }] }
      ])}
    end
  end

  def genotyping_status
    primary_aliquot.present? ? primary_aliquot.sample.genotyping_done : ''
  end

  def qc_report
    # well must be from a stock plate
    return {} unless plate.try(:stock_plate?)

    qc_data = super

    qc_data.merge!(well: map.description,
                   concentration: well_attribute.concentration,
                   sequenom_count: "#{get_sequenom_count.to_i}/30",
                   sequenom_gender: get_gender_markers,
                   pico: well_attribute.pico_pass,
                   is_in_fluidigm: fluidigm_stamp_date,
                   gel: well_attribute.gel_pass,
                   plate_barcode: plate.barcode,
                   measured_volume: well_attribute.measured_volume,
                   current_volume: well_attribute.current_volume,
                   gel_qc_date: gel_qc_date,
                   pico_date: pico_date,
                   qc_started_date: plate.qc_started_date,
                   sequenom_stamp_date: plate.sequenom_stamp_date,
                   quantity: well_attribute.quantity_in_micro_grams.try(:round, 3),
                   initial_volume: well_attribute.initial_volume)
    qc_data[:genotyping_status] = genotyping_status
    qc_data[:genotyping_barcode] = primary_aliquot.sample.genotyping_snp_plate_id if primary_aliquot.present?

    latest_child_well = find_latest_child_well
    if latest_child_well && latest_child_well.respond_to?(:plate)
      latest_plate = latest_child_well.plate
      if latest_plate && latest_plate.plate_purpose
        qc_data[:genotyping_plate_purpose] = latest_plate.plate_purpose.name
        qc_data[:genotyping_infinium_barcode] = latest_plate.infinium_barcode
        qc_data[:genotyping_barcode] = latest_plate.barcode if latest_plate.barcode
        qc_data[:genotyping_well] = latest_child_well.map_description if latest_plate.barcode
      end
    end

    qc_data
  end
end
