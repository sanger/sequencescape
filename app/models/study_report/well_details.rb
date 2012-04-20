module StudyReport::WellDetails
  def self.included(base)
    base.class_eval do
      named_scope :for_study_report, { :include => [
        :map, :well_attribute, { :plate => :plate_purpose, :primary_aliquot => { :sample => :sample_metadata } }
      ] }
    end
  end

  def dna_qc_request_status
    requests_status = dna_qc_requests_status
    return nil if requests_status.blank?
    most_recent_status = requests_status.last
    return "failed" if most_recent_status == "blocked"

    most_recent_status
  end

  def dna_qc_requests_status
    requests_status(RequestType.dna_qc)
  end

  def genotyping_requests_status
    requests_status(RequestType.genotyping)
  end

  def genotyping_status
    primary_aliquot.present? ? primary_aliquot.sample.genotyping_done : ''
  end

  def qc_report
    # well must be from a stock plate
    return nil if !(self.plate && self.plate.stock_plate?)
    qc_data = super

    qc_data.merge!({
      :well            => self.map.description,
      :concentration   => self.well_attribute.concentration,
      :sequenom_count  => "#{self.get_sequenom_count.to_i}/30",
      :sequenom_gender => self.get_gender_markers,
      :pico => self.well_attribute.pico_pass,
      :gel => self.well_attribute.gel_pass,
      :plate_barcode => self.plate.barcode,
      :measured_volume => self.well_attribute.measured_volume,
      :gel_qc_date => self.gel_qc_date,
      :pico_date => self.pico_date,
      :qc_started_date => self.plate.qc_started_date,
      :sequenom_stamp_date => self.plate.sequenom_stamp_date
    })
    qc_data[:genotyping_status] = self.genotyping_status
    qc_data[:genotyping_barcode] = self.primary_aliquot.sample.genotyping_snp_plate_id if primary_aliquot.present?

    child_plate = self.find_child_plate
    if child_plate && child_plate.respond_to?(:plate)
      if child_plate.plate && child_plate.plate.plate_purpose
        qc_data[:genotyping_plate_purpose] = child_plate.plate.plate_purpose.name
        qc_data[:genotyping_infinium_barcode] = child_plate.plate.plate_metadata.infinium_barcode
        qc_data[:genotyping_barcode] = child_plate.plate.barcode if child_plate.plate.barcode
        qc_data[:genotyping_well] = child_plate.try(:map).try(:description) if child_plate.plate.barcode
      end
    end
    qc_data[:qc_status] = dna_qc_request_status

    qc_data
  end

end
