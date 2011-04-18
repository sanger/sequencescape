module SampleManifest::TubeManifest
  
  def print_stock_tube_labels(barcode_printer,samples_data)
    printables = []
    samples_data.each do |barcode,sanger_sample_id,prefix|
      printables.push BarcodeLabel.new({ :number => barcode, :study => "#{sanger_sample_id}", :suffix => "", :prefix => prefix })
    end
    begin
      unless printables.empty?
        printables = printables.each{ |printable| printable.study = self.study.abbreviation }
        barcode_printer.print printables, barcode_printer.name, 'NT'
      end
    rescue SOAP::FaultError
      return false
    end
    true
  end
  
  def generate_1dtubes(worksheet, count, barcode_printer, default_values)
    current_row = self.spreadsheet_offset
    tubes = []
    self.barcodes = []

    sanger_ids = generate_sanger_ids(count)
    study_abbreviation = self.study.abbreviation
    samples_data = []

    if @column_position_map
      barcode_position = @column_position_map['SANGER PLATE ID']
      sample_id_position = @column_position_map['SANGER SAMPLE ID']
    else
      barcode_position = 0
      sample_id_position = 2
    end

    1.upto(count).each do |i|
      sample_tube = SampleTube.create!
      self.barcodes << sample_tube.sanger_human_barcode
      sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)
      worksheet[current_row, barcode_position] = sample_tube.sanger_human_barcode
      worksheet[current_row, sample_id_position] = sanger_sample_id

      fill_row_with_default_values(worksheet, current_row, default_values)

      current_row = current_row + 1
      tubes << sample_tube
      samples_data << [sample_tube.barcode,sanger_sample_id,sample_tube.prefix]
    end
    delayed_sample_tube_sample_creation(samples_data,self.study.id)
    delayed_generate_asset_requests(tubes, self.study)
    save!

    print_stock_tube_labels(barcode_printer,samples_data)
  end

  def delayed_sample_tube_sample_creation(samples_data,study_id)
    study_samples_data = []
    samples_data.each do |barcode,sanger_sample_id,prefix|
      sample = SampleManifest.create_sample("", self, sanger_sample_id)
      sample_tube = SampleTube.find_by_barcode(barcode)
      sample_tube.sample = sample
      sample_tube.save!
      study_samples_data << [study_id, sample.id]
    end
    self.delayed_generate_study_samples(study_samples_data)
  end
  handle_asynchronously :delayed_sample_tube_sample_creation

  
end

