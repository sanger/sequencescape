class RemovePlateTypesFromPlatePurposes < ActiveRecord::Migration
  def up
    %w(ABgene_0765 ABgene_0800 FluidX075 FluidX03).each do |name|
      plate_purpose = PlatePurpose.find_by(name: name)
      plate_purpose.destroy if plate_purpose.present?
    end
    remove_column :plate_purposes, :cherrypickable_source, :boolean
  end

  def down
    add_column :plate_purposes, :cherrypickable_source, :boolean

    ['ABgene_0800'].each do |name|
      PlatePurpose.create!(name: name, type: 'PlatePurpose', barcode_printer_type_id: 2, cherrypickable_source: true, target_type: 'Plate')
    end

    ['ABgene_0765', 'FluidX075'].each do |name|
      PlatePurpose.create!(name: name, type: 'PlatePurpose', barcode_printer_type_id: 2, cherrypickable_source: true, target_type: 'Plate', cherrypickable_target: false)
    end
  end
end
