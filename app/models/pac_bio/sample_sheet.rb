# frozen_string_literal: true
class PacBio::SampleSheet # rubocop:todo Style/Documentation
  def header_metadata(batch)
    [
      ['Version', '1.0.0', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Unique ID', batch.id, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Type', 'Plate', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      ['Owner', 'System', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      [
        'Created By',
        batch.user.login,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil
      ],
      [
        'Comments',
        "New plate created on #{Time.zone.now}",
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil
      ],
      ['Output Path', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
    ]
  end

  def column_headers
    [
      'Well No.',
      'Sample Name',
      'DNA Template Prep Kit Box Barcode',
      'Prep Kit Parameters',
      'Binding Kit Box Barcode',
      'Binding Kit Parameters',
      'Collection Protocol',
      'CP Parameters',
      'Basecaller',
      'Basecaller Parameters',
      'Secondary Analysis Protocol',
      'Secondary Analysis Parameters',
      'Sample Comments',
      'User Field 1',
      'User Field 2',
      'User Field 3',
      'User Field 4',
      'User Field 5',
      'User Field 6',
      'Results Data Output Path'
    ]
  end

  def create_csv_from_batch(batch)
    csv_string =
      CSV.generate(row_sep: "\r\n") do |csv|
        header_metadata(batch).each { |header_row| csv << header_row }
        csv << column_headers
        requests_by_wells(batch).each { |requests| csv << row(requests, batch) }
      end
  end

  def requests_by_wells(batch)
    requests = batch.requests.for_pacbio_sample_sheet
    sorted_well_requests = requests.group_by { |r| r.target_asset.map.column_order }.sort
    sorted_well_requests.map { |_well_index, requests| requests }
  end

  def replace_non_alphanumeric(protocol)
    protocol.gsub(/[^\w]/, '_')
  end

  CONCAT_SEPARATOR = ';'

  def concat(list, sym, separator = CONCAT_SEPARATOR)
    list.map(&sym).uniq.join(separator)
  end

  def row(requests, batch) # rubocop:todo Metrics/AbcSize
    # Read these lines when secondary analysis activated
    #  replace_non_alphanumeric(library_tube.pac_bio_library_tube_metadata.protocol),
    # "JobName=DefaultJob_#{Time.now}",
    # request = requests.first

    library_tubes = requests.map(&:asset)
    first_tube_metadata = requests.first.pac_bio_library_tube_metadata
    first_request_metadata = requests.first.request_metadata

    well = requests.first.target_asset
    [
      Map.pad_description(well.map),
      concat(library_tubes, :labware_name, '-'),
      first_tube_metadata.prep_kit_barcode,
      nil,
      first_tube_metadata.binding_kit_barcode,
      nil,
      lookup_collection_protocol(requests.first),
      # rubocop:disable Layout/LineLength
      "AcquisitionTime=#{first_tube_metadata.movie_length}|InsertSize=#{first_request_metadata.insert_size}|StageHS=True|SizeSelectionEnabled=False|Use2ndLook=False|NumberOfCollections=#{requests.size}",
      # rubocop:enable Layout/LineLength
      'Default',
      nil,
      nil,
      nil,
      nil,
      well.uuid,
      concat(library_tubes, :uuid),
      batch.uuid,
      well.plate.barcode_for_pac_bio_manifest,
      concat(requests, :uuid),
      nil,
      nil
    ]
  end

  def lookup_collection_protocol(request)
    return 'Standard Seq v3' if request.request_metadata.sequencing_type == 'Standard'
    return 'MagBead Standard Seq v2' if request.request_metadata.sequencing_type == 'MagBead'

    request.request_metadata.sequencing_type
  end
end
