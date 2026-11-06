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
                null: false,
                comment: 'Barcode_Plate_Num in Ultima sample sheets, e.g. 1'

      t.timestamps
    end
  end
end
