# frozen_string_literal: true

class CreateUltimaTagGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :ultima_tag_groups,
                 comment: 'Ultima data for a tag group in tag_groups, ' \
                          'one row per Ultima tag group' do |t|
      t.references :tag_group,
                   type: :integer,
                   null: false,
                   index: { unique: true },
                   foreign_key: true,
                   comment: 'The tag group this Ultima data is for'
      t.integer :barcode_plate_num,
                comment: 'Barcode_Plate_Num in Ultima sample sheets, e.g. 1; ' \
                         'NULL when Ultima gives no plate number, and then ' \
                         'the sheet leaves the column out'

      t.timestamps
    end
  end
end
