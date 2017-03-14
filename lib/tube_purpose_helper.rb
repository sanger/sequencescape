# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
module TubePurposeHelper
  class PurposeMigrator
    attr_reader :purposes, :migration
    delegate :say, to: :migration
    def initialize(purposes, migration)
      @purposes = purposes
      @migration = migration
    end

    def to(target_purpose)
      purposes.each do |name|
        say "Updating #{name}..."
        Purpose.find_by(name: name).child_relationships.first.update_attributes!(child: target_purpose)
      end
    end
  end

  class RequestTypeMigrator
    attr_reader :request_types, :migration
    delegate :say, to: :migration
    def initialize(request_types, migration)
      @request_types = request_types
      @migration = migration
    end

    def to(target_purpose)
      request_types.each do |key|
        say "Updating #{key}..."
        RequestType.find_by!(key: key).update_attributes!(target_purpose_id: target_purpose.id)
      end
    end

    def repair_data(old_purpose, new_purpose)
      request_types.each do |key|
        say "Repairing #{key}..."
        rt = RequestType.find_by!(key: key)
        updated = 0
        MultiplexedLibraryTube.find_each(
          select: 'DISTINCT assets.*',
          joins: 'LEFT JOIN requests ON requests.target_asset_id = assets.id',
          conditions: ['assets.plate_purpose_id = ? AND request_type_id = ?', old_purpose.id, rt.id]
        ) do |library_tube|
          library_tube.update_attributes!(purpose: new_purpose)
          updated += 1
        end
        say "#{updated} assets updated"
      end
    end
  end

  def migrate_purposes(*purposes)
    PurposeMigrator.new(purposes, self)
  end

  def migrate_request_types(*request_types)
    RequestTypeMigrator.new(request_types, self)
  end

  def new_illumina_mx_tube(name)
    say "Creating '#{name}'' purpose"
    IlluminaHtp::MxTubeNoQcPurpose.create!(
        name: name,
        target_type: 'MultiplexedLibraryTube',
        qc_display: false,
        stock_plate: false,
        default_state: 'pending',
        barcode_printer_type: BarcodePrinterType.find_by(name: '1D Tube'),
        cherrypickable_target: false,
        cherrypickable_source: false,
        cherrypick_direction: 'column',
        barcode_for_tecan: 'ean13_barcode'
      )
  end
end
