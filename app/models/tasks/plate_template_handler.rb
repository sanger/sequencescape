# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

# Gets included in the WorkflowsController and adds a load of methods
# to handle the first step of cherrypicking (selecting templates etc.)
# Not a great pattern to follow, although its very prevalent in the workflows.
module Tasks::PlateTemplateHandler
  # Class to extract the layout from an uploaded spreadsheet
  class SpreadsheetReader
    def initialize(csv_string, batch, plate_size)
      @csv_string = csv_string
      @requests = batch.requests.includes(asset: [:map, { plate: :barcodes }]).index_by(&:id)
      @plate_size = plate_size
    end

    def layout
      barcodes = Set.new
      plates = mapped_plate_wells.each_value.map do |mapped_wells|
        Array.new(plate_size) do |i|
          request_id = mapped_wells[i]
          if request_id.present?
            asset = requests[request_id].asset
            barcodes << asset.plate.barcode_number
            [request_id, asset.plate.barcode_number, asset.display_name]
          else
            CherrypickTask::EMPTY_WELL
          end
        end
      end

      [plates, barcodes.to_a]
    end

    private

    def mapped_plate_wells
      (Hash.new { |h, k| h[k] = {} }).tap do |parsed_plates|
        CSV.parse(csv_string, headers: :first_row) do |row|
          parse_spreadsheet_row(row['Request ID'], row['Plate'], row['Destination Well']) do |plate_key, request_id, location|
            parsed_plates[plate_key][location.column_order] = request_id
          end
        end
      end
    end

    def parse_spreadsheet_row(request_id, plate_key, destination_well)
      return if request_id.blank? || request_id.to_i.zero?
      location = locations[destination_well] || return
      yield(plate_key.presence || 'default plate 1', request_id.to_i, location)
    end

    def locations
      @locations ||= Map.where(asset_size: plate_size).index_by(&:description)
    end

    attr_reader :requests, :plate_size, :csv_string
  end

  def render_plate_template_task(task, _params)
    @robots = Robot.all
    @plate_purpose_options = task.plate_purpose_options(@batch)
    suitable_sizes = @plate_purpose_options.map { |o| o[1] }.uniq
    @plate_templates = PlateTemplate.with_sizes(suitable_sizes)
  end

  def do_plate_template_task(_task, params)
    return true if params[:file].blank?

    plate_size = if params[:plate_template].blank?
                   PlatePurpose.find(params[:plate_purpose_id]).size
                 else
                   PlateTemplate.find(params[:plate_template]['0'].to_i).size
                 end
    @spreadsheet_layout = SpreadsheetReader.new(params[:file].read, @batch, plate_size).layout
    true
  end

  def self.generate_spreadsheet(batch)
    CSV.generate(row_sep: "\r\n") do |csv|
      csv << ['Request ID', 'Sample Name', 'Plate', 'Destination Well']
      batch.requests.each { |r| csv << [r.id, r.asset.sample.name, '', ''] }
    end
  end
end
