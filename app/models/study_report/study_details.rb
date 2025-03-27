# frozen_string_literal: true
# rubocop:todo Metrics/ModuleLength
module StudyReport::StudyDetails
  BATCH_SIZE = 1000

  # This will pull out all well ids from stock plates in the study
  def each_stock_well_id_in_study_in_batches(&) # rubocop:todo Metrics/MethodLength
    # Stock wells are determined by the requests leading from the stock plate
    handle_wells(
      :requests,
      { requests: { initial_study_id: id } },
      PlatePurpose.where(name: Study::STOCK_PLATE_PURPOSES).pluck(:id),
      &
    )

    # Aliquot 1,2,3,4 & 5 plates are determined by the aliquots in their wells
    handle_wells(
      :aliquots,
      { aliquots: { study_id: id } },
      PlatePurpose.where(
        name: ['Aliquot 1', 'Aliquot 2', 'Aliquot 3', 'Aliquot 4', 'Aliquot 1', 'Pre-Extracted Plate']
      ).pluck(:id),
      &
    )
  end

  # Similar to find in batches, we pluck out the relevant asset ids, then slice them into batches of the
  # batch size. This allows us to perform one query to grab all our ids.
  def handle_wells(join, study_condition, plate_purpose_id, &)
    asset_ids = well_report_ids(join, study_condition, plate_purpose_id)
    asset_ids.each_slice(BATCH_SIZE, &)
  end
  private :handle_wells

  def well_report_ids(join, study_condition, plate_purpose_id)
    Well.joins(:plate, join).on_plate_purpose(plate_purpose_id).where(study_condition).order(id: :asc).uniq.pluck(:id)
  end
  private :well_report_ids

  def progress_report_header
    [
      'Status',
      'Study',
      'Supplier',
      'Sanger Sample Name',
      'Supplier Sample Name',
      'Plate',
      'Well',
      'Supplier Volume',
      'Supplier Gender',
      'Concentration',
      'Initial Volume',
      'Current Volume',
      'Total Micrograms',
      'Sequenome Count',
      'Sequenome Gender',
      'Pico',
      'Gel',
      'Qc Status',
      'QC started date',
      'Pico date',
      'Gel QC date',
      'Seq stamp date',
      'Cohort',
      'Country of Origin',
      'Geographical Region',
      'Ethnicity',
      'DNA Source',
      'Is Resubmitted',
      'Control',
      'Is in Fluidigm'
    ]
  end

  # rubocop:todo Metrics/MethodLength
  def progress_report_on_all_assets # rubocop:todo Metrics/AbcSize
    yield(progress_report_header)

    each_stock_well_id_in_study_in_batches do |asset_ids|
      # eager loading of well_attribute , can only be done on  wells ...
      # We've already split into batches, so find_each here only slows things down.
      Well
        .for_study_report
        .where(id: asset_ids)
        .order(:id)
        .each do |asset|
          asset_progress_data = asset.qc_report
          next if asset_progress_data.nil?

          yield(
            [
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
              asset_progress_data[:current_volume],
              asset_progress_data[:quantity],
              asset_progress_data[:sequenom_count],
              [asset_progress_data[:sequenom_gender]].flatten.compact.join(''),
              asset_progress_data[:pico],
              asset_progress_data[:gel],
              asset_progress_data[:qc_status],
              asset_progress_data[:qc_started_date],
              asset_progress_data[:pico_date],
              asset_progress_data[:gel_qc_date],
              asset_progress_data[:sequenom_stamp_date],
              asset_progress_data[:cohort],
              asset_progress_data[:country_of_origin],
              asset_progress_data[:geographical_region],
              asset_progress_data[:ethnicity],
              asset_progress_data[:dna_source],
              asset_progress_data[:is_resubmitted],
              asset_progress_data[:control],
              asset_progress_data[:is_in_fluidigm]
            ]
          )
        end
    end
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
