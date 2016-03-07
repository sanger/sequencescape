#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2014 Genome Research Ltd.
class PacBio::Worksheet

  def initialize
  end

  def create_csv_from_batch(batch)
    csv_string = CSV.generate( :row_sep => "\r\n") do |csv|
      header_metadata(batch).each{ |header_row| csv << header_row }
      csv << column_headers
      batch.requests.each_with_index do |request,index|
        csv << ( row(request))
      end
    end
  end

  protected

  def header_metadata(batch)
    [
      ["Batch #{batch.id}"],
      ["Sample", "", "Fragmentation", "", "End repair and ligation","","","","QC","",""]
    ]
  end

  def column_headers
    ["Well", "Name", "Required size", "Complete?", "Repaired?", "Adapter ligated?", "Clean up complete?", "Exonnuclease cleanup", "ng/ul", "Fragment size", "Volume"]
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
