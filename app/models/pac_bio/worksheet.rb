# frozen_string_literal: true
class PacBio::Worksheet
  def create_csv_from_batch(batch)
    csv_string =
      CSV.generate(row_sep: "\r\n") do |csv|
        header_metadata(batch).each { |header_row| csv << header_row }
        csv << column_headers
        batch.requests.each_with_index { |request, _index| csv << row(request) }
      end
  end

  protected

  def header_metadata(batch)
    [["Batch #{batch.id}"], ['Sample', '', 'Fragmentation', '', 'End repair and ligation', '', '', '', 'QC', '', '']]
  end

  def column_headers
    [
      'Well',
      'Name',
      'Required size',
      'Complete?',
      'Repaired?',
      'Adapter ligated?',
      'Clean up complete?',
      'Exonnuclease cleanup',
      'ng/ul',
      'Fragment size',
      'Volume'
    ]
  end

  def row(request)
    [
      request.asset.display_name,
      request.asset.primary_aliquot.sample.name,
      request.request_metadata.insert_size,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      ''
    ]
  end
end
