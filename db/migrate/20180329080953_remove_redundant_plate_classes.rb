# frozen_string_literal: true

# We have a large number of plate classes which only changed the barcode
# prefix. We can now eliminate them
class RemoveRedundantPlateClasses < ActiveRecord::Migration[5.1]
  MIGRATIONS = [
    # [ 'original', 'new', 'prefix']
    %w[PicoAssayAPlate PicoAssayPlate PA],
    %w[PicoAssayBPlate PicoAssayPlate PB],
    %w[PulldownAliquotPlate Plate FA],
    %w[PulldownEnrichmentFourPlate Plate FM],
    %w[PulldownEnrichmentOnePlate Plate FG],
    %w[PulldownEnrichmentThreePlate Plate FK],
    %w[PulldownEnrichmentTwoPlate Plate FI],
    %w[PulldownPcrPlate Plate FQ],
    %w[PulldownQpcrPlate Plate FS],
    %w[PulldownRunOfRobotPlate Plate FE],
    %w[PulldownSequenceCapturePlate Plate FO],
    %w[PulldownSonicationPlate Plate FC]
    # Can't remove this at the moment as use the class in a controller
    # %w[GelDilutionPlate WorkingDilutionPlate GD]
  ].freeze
  def up
    ActiveRecord::Base.transaction do
      MIGRATIONS.each do |original, new_type, _prefix|
        Asset.where(sti_type: original).update_all(sti_type: new_type)
        Purpose.where(target_type: original).update_all(target_type: new_type)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      MIGRATIONS.each do |original, new_type, prefix|
        Purpose
          .where(target_type: new_type)
          .joins('LEFT JOIN barcode_prefixes ON barcode_prefixes.id = plate_purposes.barcode_prefix_id')
          .where(barcode_prefixes: { prefix: })
          .find_each do |purpose|
            purpose.target_type = original
            purpose.save
            Asset.where(plate_purpose_id: purpose.id).update_all(sti_type: original)
          end
      end
    end
  end
end
