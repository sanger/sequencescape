module SampleManifest::PlateManifest
  def generate_plates(worksheet, count, barcode_printer, default_values)
    current_row = self.spreadsheet_offset
    plates = create_plates_ordered_by_barcodes(count)
    self.barcodes = plates.map{ |plate| plate.sanger_human_barcode }
    study_abbreviation = self.study.abbreviation

    plates.each_with_index do |plate,i|
      plate_sanger_barcode = plate.sanger_human_barcode
      sanger_sample_ids = generate_sanger_ids(plate.size)
      position = "A1"
      well_data = []

      if @column_position_map
        barcode_position = @column_position_map['SANGER PLATE ID']
        position_position = @column_position_map['WELL']
        sample_id_position = @column_position_map['SANGER SAMPLE ID']
      else
        barcode_position = 0
        position_position = 1
        sample_id_position = 2
      end

      while position
        sanger_sample_id = sanger_sample_ids.shift
        generated_sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_sample_id)
        
        worksheet[current_row, barcode_position] = plate_sanger_barcode
        worksheet[current_row, position_position] = position
        worksheet[current_row, sample_id_position] = generated_sanger_sample_id

        fill_row_with_default_values(worksheet, current_row, default_values)
        
        well_data << [position, generated_sanger_sample_id]
        current_row = current_row + 1
        position = Map.next_vertical_map_position_from_description(position,plate.size).try(:description)
      end
      delayed_generate_wells(well_data, plate.id, self.study.id, self.id)

    end
    delayed_generate_asset_requests(plates, self.study)
    save!

    print_stock_plate_labels(barcode_printer, plates.reverse)
  end
  
  def delayed_generate_wells(well_data, plate_id, study_id, manifest_id)
    ActiveRecord::Base.transaction do 
      wells_to_create = []
      plate = Plate.find(plate_id)
      manifest = SampleManifest.find(manifest_id)
      study_samples_data = []
      well_data.each do |position,sanger_sample_id|
        sample = SampleManifest.create_sample("", manifest, sanger_sample_id)
        map = Map.find_by_description_and_asset_size(position,plate.size)
        Well.create!(:plate => plate, :map => map, :sample => sample)
        study_samples_data << [study_id, sample.id]
      end
      manifest.delayed_generate_study_samples(study_samples_data)
      plate.save!
      plate.reload
      plate.create_well_attributes(plate.wells)
      plate.events.created_using_sample_manifest!(manifest.user)

      RequestFactory.create_assets_requests(plate.wells.map(&:id), study_id)
    end

    nil
  end
  handle_asynchronously :delayed_generate_wells
  
  
  def print_stock_plate_labels(barcode_printer,plates)
    printables = stock_plate_purpose.create_barcode_labels_from_plates(plates)
    begin
      unless printables.empty?
        printables = printables.each{ |printable| printable.study = self.study.abbreviation }
        barcode_printer.print printables, barcode_printer.name, Plate.prefix, "long", "#{stock_plate_purpose.name}"
      end
    rescue
      return false
    end

    true
  end

  delegate :stock_plate_purpose, :to => 'PlatePurpose'
  
  def plates_update_events(samples, current_user)
    find_plates_from_samples(samples).each do |plate|
      plate.events.updated_using_sample_manifest!(current_user)
    end
  end
  
  def find_plates_from_samples(samples)
    plates = []
    samples.each do |sample|
      sample.assets.each do |well|
        next unless well.is_a?(Well)
        plates << well.plate if well.plate
      end
    end
    plates.uniq
  end
  
  def create_plates_ordered_by_barcodes(count)
    plates = []
    1.upto(count).each do |i|
      plate = Plate.create_plate_with_barcode
      plate.update_attributes!(:plate_purpose => PlatePurpose.stock_plate_purpose)
      plates << plate
    end
    
    plates.sort{ |a,b| a.barcode <=> b.barcode }
  end
  
  
end
