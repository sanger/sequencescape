class PlatePurpose < ActiveRecord::Base
  class Relationship < ActiveRecord::Base
    set_table_name('plate_purpose_relationships')
    belongs_to :parent, :class_name => 'PlatePurpose'
    belongs_to :child, :class_name => 'PlatePurpose'

    module Associations
      def self.included(base)
        base.class_eval do
          has_many :child_relationships, :class_name => 'PlatePurpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
          has_many :child_plate_purposes, :through => :child_relationships, :source => :child

          has_many :parent_relationships, :class_name => 'PlatePurpose::Relationship', :foreign_key => :child_id, :dependent => :destroy
          has_many :parent_plate_purposes, :through => :parent_relationships, :source => :parent
        end
      end
    end
  end
  include Relationship::Associations

end
class IlluminaB::StockPlatePurpose < PlatePurpose
end
class IlluminaB::TaggedPlatePurpose < PlatePurpose
end

class AddPlatePurposesForIlluminaBPipeline < ActiveRecord::Migration

  @barcode_printer_type_id = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate').id
  @plate_purposes = [
      {
        :name => 'ILB_STD_INPUT',
        :type => IlluminaB::StockPlatePurpose,
        :qc_display => 0,
        :can_be_considered_a_stock_plate => 1,
        :default_state => 'passed',
        :barcode_printer_type_id => @barcode_printer_type_id,
        :cherrypickable_target => 1,
        :cherrypick_direction => 'row'
      },
      {
        :name => 'ILB_STD_PCRXP',
        :type => IlluminaB::TaggedPlatePurpose,
        :qc_display => 0,
        :can_be_considered_a_stock_plate => 0,
        :default_state => 'pending',
        :barcode_printer_type_id => @barcode_printer_type_id,
        :cherrypickable_target => 0,
        :cherrypick_direction => 'row'
      }
    ]
  @child_plate_purposes = {
    'ILB_STD_INPUT' => 'ILB_STD_PCRXP'
  }

  def self.up
    ActiveRecord::Base.transaction do
      @plate_purposes.each do |config|
        config[:type].create!(config)
      end
      @child_plate_purposes.each do |parent,child|
        PlatePurpose.find_by_name(parent).child_plate_purposes << PlatePurpose.find_by_name(child)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      @plate_purposes.each do |config|
        PlatePurpose.find_by_name(config[:name]).destroy
      end
    end
  end
end
