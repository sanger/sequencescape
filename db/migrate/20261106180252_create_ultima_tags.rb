# frozen_string_literal: true

class CreateUltimaTags < ActiveRecord::Migration[8.1]
  def change
    create_table :ultima_tags,
                 comment: 'Ultima data for a tag in tags, ' \
                          'one row per tag in an Ultima tag group' do |t|
      t.references :tag,
                   type: :integer,
                   null: false,
                   index: { unique: true },
                   foreign_key: true,
                   comment: 'The tag this Ultima data is for'
      t.string :index_barcode_num,
               null: false,
               comment: 'Index_Barcode_Num (Z number) in Ultima sample ' \
                        'sheets, e.g. Z0001'
      t.string :barcode_plate_well,
               null: false,
               comment: 'Barcode_Plate_Well in Ultima sample sheets, e.g. A1'

      t.timestamps
    end
  end
end
