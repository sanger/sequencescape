# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

module StudyReport::StudyDetails
  BATCH_SIZE = 1000

  # This will pull out all well ids from stock plates in the study
  def each_stock_well_id_in_study_in_batches(&block)
    # Stock wells are determined by the requests leading from the stock plate
    handle_wells(
      :requests,
      { requests: { initial_study_id: id } },
      PlatePurpose.where(name: Study::STOCK_PLATE_PURPOSES).pluck(:id),
      &block
    )

    # Aliquot 1,2,3,4 & 5 plates are determined by the aliquots in their wells
    handle_wells(
      :aliquots,
      { aliquots: { study_id: id } },
      PlatePurpose.where(name: ['Aliquot 1', 'Aliquot 2', 'Aliquot 3', 'Aliquot 4', 'Aliquot 1', 'Pre-Extracted Plate']).pluck(:id),
      &block
    )
  end

  # Similar to find in batches, we pluck out the relevant asset ids, then slice them into batches of the
  # batch size. This allows us to perform one query to grab all our ids.
  def handle_wells(join, study_condition, plate_purpose_id, &block)
    asset_ids = well_report_ids(join, study_condition, plate_purpose_id)
    asset_ids.each_slice(BATCH_SIZE, &block)
  end
  private :handle_wells

  def well_report_ids(join, study_condition, plate_purpose_id)
    Well.joins(:plate, join)
      .where(plates_assets: { plate_purpose_id: plate_purpose_id })
      .where(study_condition)
      .order(id: :asc).uniq.pluck(:id)
  end
  private :well_report_ids

  def progress_report_header
    [
      'Status', 'Study', 'Supplier', 'Sanger Sample Name', 'Supplier Sample Name', 'Plate', 'Well', 'Supplier Volume',
      'Supplier Gender', 'Concentration', 'Initial Volume', 'Current Volume', 'Total Micrograms', 'Sequenome Count',
      'Sequenome Gender', 'Pico', 'Gel', 'Qc Status', 'QC started date', 'Pico date', 'Gel QC date', 'Seq stamp date',
      'Genotyping Status', 'Genotyping Chip', 'Genotyping Infinium Barcode', 'Genotyping Barcode', 'Genotyping Well',
      'Cohort', 'Country of Origin', 'Geographical Region', 'Ethnicity', 'DNA Source', 'Is Resubmitted', 'Control', 'Is in Fluidigm'
    ]
  end

  def progress_report_on_all_assets
    yield(progress_report_header)
    each_stock_well_id_in_study_in_batches do |asset_ids|
      # eager loading of well_attribute , can only be done on  wells ...
      # We've already split into batches, so find_each here only slows things down.
      Well.for_study_report.where(id: asset_ids).each do |asset| # rubocop:disable Rails/FindEach
        asset_progress_data = asset.qc_report
        next if asset_progress_data.nil?

        yield([
          asset_progress_data[:status],
          name,
          asset_progress_data[:supplier],
          asset_progress_data[:sanger_sample_id],
          asset_progress_data[:sample_name],
          asset_progress_data[:plate_barcode],
          asset_progress_data[:well],
          asset_progress_data[:supplier_volume],
          asset_progress_data[:supplier_gender],
          asset_progress_data[:concentration],
          asset_progress_data[:initial_volume],
          # asset_progress_data[:measured_volume],
          asset_progress_data[:current_volume],
          asset_progress_data[:quantity],
          asset_progress_data[:sequenom_count],
          [(asset_progress_data[:sequenom_gender])].flatten.compact.join(''),
          asset_progress_data[:pico],
          asset_progress_data[:gel],
          asset_progress_data[:qc_status],
          asset_progress_data[:qc_started_date],
          asset_progress_data[:pico_date],
          asset_progress_data[:gel_qc_date],
          asset_progress_data[:sequenom_stamp_date],
          asset_progress_data[:genotyping_status],
          asset_progress_data[:genotyping_plate_purpose],
          asset_progress_data[:genotyping_infinium_barcode],
          asset_progress_data[:genotyping_barcode],
          asset_progress_data[:genotyping_well],
          asset_progress_data[:cohort],
          asset_progress_data[:country_of_origin],
          asset_progress_data[:geographical_region],
          asset_progress_data[:ethnicity],
          asset_progress_data[:dna_source],
          asset_progress_data[:is_resubmitted],
          asset_progress_data[:control],
          asset_progress_data[:is_in_fluidigm]
        ])
      end
    end
  end
end
