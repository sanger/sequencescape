# frozen_string_literal: true

# Uses existing behaviour to ensure purposes are correctly populated
class PopulateExistingPurposesWithPrefixData < ActiveRecord::Migration[5.1]
  # Reopen the purpose class for the purposes of this migration
  class Purpose < ApplicationRecord
    self.table_name = 'plate_purposes'
    self.inheritance_column = nil
  end

  MIGRATE = {
    'Plate' => 'DN',
    'PlateTemplate' => 'DN',
    'ControlPlate' => 'DN',
    'DilutionPlate' => 'DN',
    'PicoAssayPlate' => 'PA',
    'PulldownPlate' => 'DN',
    'SequenomQcPlate' => 'DN',
    'StripTube' => 'LS',
    'WorkingDilutionPlate' => 'WD',
    'PicoDilutionPlate' => 'PD',
    'GelDilutionPlate' => 'GD',
    'PicoAssayAPlate' => 'PA',
    'PicoAssayBPlate' => 'PB',
    'PulldownAliquotPlate' => 'FA',
    'PulldownEnrichmentFourPlate' => 'FM',
    'PulldownEnrichmentOnePlate' => 'FG',
    'PulldownEnrichmentThreePlate' => 'FK',
    'PulldownEnrichmentTwoPlate' => 'FI',
    'PulldownPcrPlate' => 'FQ',
    'PulldownQpcrPlate' => 'FS',
    'PulldownRunOfRobotPlate' => 'FE',
    'PulldownSequenceCapturePlate' => 'FO',
    'PulldownSonicationPlate' => 'FC',
    'Tube' => 'NT',
    'SampleTube' => 'NT',
    'LibraryTube' => 'NT',
    'StockLibraryTube' => 'NT',
    'MultiplexedLibraryTube' => 'NT',
    'StockMultiplexedLibraryTube' => 'NT',
    'PulldownMultiplexedLibraryTube' => 'NT',
    'PacBioLibraryTube' => 'NT',
    'SpikedBuffer' => 'NT',
    'QcTube' => 'NT'
  }.freeze

  def up
    ActiveRecord::Base.transaction do
      MIGRATE.each do |asset_class, prefix|
        Purpose
          .where(target_type: asset_class)
          .find_each do |purpose|
            purpose.barcode_prefix_id = BarcodePrefix.find_by(prefix:).id
            purpose.save!
          end
      end
    end
  end

  def down
    Purpose.update_all(barcode_prefix_id: nil)
  end
end
