module StudyReport::StudyDetails

  # This will pull out all well ids from stock plates in the study
  def each_stock_well_id_in_study_in_batches(&block)
    Asset.find_in_batches(:select => "assets.id",
                          :from => 'assets, aliquots a, assets plate, container_associations ca',
                          :conditions => ["assets.sti_type='Well' and plate.sti_type='Plate' and " +
                                         "a.study_id=? and a.receptacle_id=assets.id and " +
                                         "ca.container_id=plate.id and ca.content_id=assets.id and " +
                                         "plate.plate_purpose_id in (2, 84, 85, 86, 87, 88)", self.id]
                         ) do |well_ids|
                           block.call(well_ids)
    end
  end

  def progress_report_header
    [
      "Status","Study","Supplier","Sanger Sample Name","Supplier Sample Name","Plate","Well","Supplier Volume",
      "Supplier Gender", "Concentration","Measured Volume","Sequenome Count", "Sequenome Gender",
      "Pico","Gel", "Qc Status", "QC started date", "Pico date", "Gel QC date","Seq stamp date","Genotyping Status", "Genotyping Chip", "Genotyping Infinium Barcode", "Genotyping Barcode","Genotyping Well", "Cohort", "Country of Origin",
      "Geographical Region","Ethnicity","DNA Source","Is Resubmitted","Control"
      ]
  end

  def progress_report_on_all_assets (&block)
    block.call(progress_report_header)
    each_stock_well_id_in_study_in_batches do |asset_ids|

      # eager loading of well_attribute , can only be done on  wells ...
      assets = Well.find(:all, :include => :well_attribute, :conditions => {:id => asset_ids}, :include => { :aliquots => :sample })

      assets.each do |asset|
        asset_progress_data = asset.qc_report
        next if asset_progress_data.nil?

        block.call([
                   asset_progress_data[:status],
                   self.name,
                   asset_progress_data[:supplier],
                   asset_progress_data[:sanger_sample_id],
                   asset_progress_data[:sample_name],
                   asset_progress_data[:plate_barcode],
                   asset_progress_data[:well],
                   asset_progress_data[:supplier_volume],
                   asset_progress_data[:supplier_gender],
                   asset_progress_data[:concentration],
                   asset_progress_data[:measured_volume],
                   asset_progress_data[:sequenom_count],
                   asset_progress_data[:sequenom_gender],
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
                   asset_progress_data[:control]
        ])
      end
    end
  end

end
