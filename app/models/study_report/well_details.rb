#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

module StudyReport::WellDetails
  def self.included(base)
    base.class_eval do
      scope :for_study_report, -> { includes([
        :map,
        :well_attribute,
        :events,
        { :plate => [:plate_purpose,:events], :primary_aliquot => { :sample => [:sample_metadata,{:sample_manifest=>:supplier},:external_properties] } },
        { :latest_child_well => [:map, {:plate => [:plate_purpose,:plate_metadata]}]}
      ])}
    end
  end

  def genotyping_status
    primary_aliquot.present? ? primary_aliquot.sample.genotyping_done : ''
  end

  def qc_report
    # well must be from a stock plate
    return {} unless self.plate.try(:stock_plate?)

    qc_data = super

    qc_data.merge!({
      :well            => self.map.description,
      :concentration   => self.well_attribute.concentration,
      :sequenom_count  => "#{self.get_sequenom_count.to_i}/30",
      :sequenom_gender => self.get_gender_markers,
      :pico => self.well_attribute.pico_pass,
      :is_in_fluidigm => self.fluidigm_stamp_date,
      :gel => self.well_attribute.gel_pass,
      :plate_barcode => self.plate.barcode,
      :measured_volume => self.well_attribute.measured_volume,
      :gel_qc_date => self.gel_qc_date,
      :pico_date => self.pico_date,
      :qc_started_date => self.plate.qc_started_date,
      :sequenom_stamp_date => self.plate.sequenom_stamp_date,
      :quantity => self.well_attribute.quantity_in_micro_grams.try(:round,3),
      :initial_volume => self.well_attribute.initial_volume
    })
    qc_data[:genotyping_status] = self.genotyping_status
    qc_data[:genotyping_barcode] = self.primary_aliquot.sample.genotyping_snp_plate_id if primary_aliquot.present?

    latest_child_well = self.find_latest_child_well
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
