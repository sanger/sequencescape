class CreateMissingPlateCreators < ActiveRecord::Migration
  class PlateCreator < ActiveRecord::Base
    class Relationship < ActiveRecord::Base
      set_table_name('plate_creator_purposes')

      belongs_to :plate_purpose, :class_name => 'CreateMissingPlateCreators::PlatePurpose'
      belongs_to :plate_creator, :class_name => 'CreateMissingPlateCreators::PlateCreator'
    end

    set_table_name('plate_creators')

    has_many :plate_creator_purposes, :class_name => 'CreateMissingPlateCreators::PlateCreator::Relationship', :dependent => :destroy, :foreign_key => :plate_creator_id
    has_many :plate_purposes, :through => :plate_creator_purposes

    belongs_to :plate_purpose, :class_name => 'CreateMissingPlateCreators::PlatePurpose'
  end

  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
    self.inheritance_column = :_type_disabled
  end

  def self.up
    ActiveRecord::Base.transaction do
      [ 'Pico dilution', 'Working dilution' ].each do |name|
        plate_purpose = PlatePurpose.find_by_name(name) or raise StandardError, "Cannot find #{name.inspect} plate purpose"
        PlateCreator.create!(:name => name, :plate_purpose => plate_purpose, :plate_purposes => [ plate_purpose ])
      end
    end
  end

  def self.down
    PlateCreator.destroy_all([ 'name=?', [ 'Pico dilution', 'Working dilution' ]])
  end
end
