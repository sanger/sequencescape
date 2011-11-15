class RemoveIncorrectStockDnaPlatePurposeRelationships < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    class Relationship < ActiveRecord::Base
      set_table_name('plate_purpose_relationships')
      belongs_to :parent, :class_name => 'RemoveIncorrectStockDnaPlatePurposeRelationships::PlatePurpose'
      belongs_to :child, :class_name => 'RemoveIncorrectStockDnaPlatePurposeRelationships::PlatePurpose'
    end

    set_table_name('plate_purposes')
    self.inheritance_column = :not_defined_please_ignore_inheritance

    has_many :child_relationships, :class_name => 'RemoveIncorrectStockDnaPlatePurposeRelationships::PlatePurpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
    has_many :child_plate_purposes, :through => :child_relationships, :source => :child
  end

  def self.up
    ActiveRecord::Base.transaction do
      [ 'WGS', 'SC', 'ISC' ].each do |pipeline|
        stock = PlatePurpose.find_by_name("#{pipeline} stock DNA") or raise StandardError, "Cannot locate #{pipline} stock DNA plate purpose"
        stock.child_relationships.select { |r| r.child[:type] != 'Pulldown::InitialPlatePurpose' }.map(&:destroy)
      end
    end
  end

  def self.down
    # Nothing needs to be done here
  end
end
