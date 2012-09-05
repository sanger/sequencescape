class PacBio::SampleSheet
  def header_metadata(batch)
    [
      ['Version', '1.0.0', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Unique ID', batch.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Type', 'Plate', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Owner', 'System', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Created By', batch.user.login, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Comments', "New plate created on #{Time.now}", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Output Path', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    ]
  end

  def column_headers
    ['Well No.', 'Sample Name', 'DNA Template Prep Kit Box Barcode', 'Prep Kit Parameters', 'Binding Kit Box Barcode', 'Binding Kit Parameters',
      'Collection Protocol', 'CP Parameters', 'Basecaller', 'Basecaller Parameters', 'Secondary Analysis Protocol', 'Secondary Analysis Parameters',
      'Sample Comments', 'User Field 1', 'User Field 2', 'User Field 3', 'User Field 4', 'User Field 5', 'User Field 6', 'Results Data Output Path']
  end


  def create_csv_from_batch(batch)
      csv_string = FasterCSV.generate( :row_sep => "\r\n") do |csv|
        header_metadata(batch).each{ |header_row| csv << header_row }
        csv << column_headers
        requests_by_wells(batch).each do |requests|
          csv << row(requests, batch)
        end
      end
  end

  def requests_by_wells(batch)
    requests = batch.requests
    wells = requests.map{ |request| request.target_asset }.uniq
    requests_grouped_by_wells = []
    wells.each do |well|
      requests_grouped_by_wells << requests.select{ |request| request.target_asset == well }
    end

    requests_grouped_by_wells
  end

  def replace_non_alphanumeric(protocol)
    protocol.gsub(/[^\w]/,'_')
  end


  def row(requests, batch)
    # Readd these lines when secondary analysis activated
    #  replace_non_alphanumeric(library_tube.pac_bio_library_tube_metadata.protocol),
    # "JobName=DefaultJob_#{Time.now}",
    request = requests.first
    library_tube = request.asset
    well = request.target_asset
    [
      Map.pad_description(well.map),
      well.primary_aliquot.sample.name,
      library_tube.pac_bio_library_tube_metadata.prep_kit_barcode,
      nil,
      library_tube.pac_bio_library_tube_metadata.binding_kit_barcode,
      'UsedControl=true',
      lookup_collection_protocol(request),
      "AcquisitionTime=#{library_tube.pac_bio_library_tube_metadata.movie_length}|InsertSize=#{request.request_metadata.insert_size}|NumberOfCollections=#{requests.size}",
      'Default',
      nil,
      '',
      '',
      nil,
      well.uuid,
      library_tube.uuid,
      batch.uuid,
      well.plate.barcode,
      request.uuid,
      nil,
      nil
      ]
  end

  def lookup_collection_protocol(request)
    return 'Standard Seq 2-Set v1' if request.request_metadata.sequencing_type == 'Standard'
    return 'Default Strobe Sequencing' if request.request_metadata.sequencing_type == 'Strobe'
    request.request_metadata.sequencing_type
  end

end

