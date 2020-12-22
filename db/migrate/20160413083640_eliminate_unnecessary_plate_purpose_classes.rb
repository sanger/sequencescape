# Rails migration

# Previously these classes handled some differences in business logic. This
# complexity has been pushed outwards.
class EliminateUnnecessaryPlatePurposeClasses < ActiveRecord::Migration
  class Purpose < ApplicationRecord # rubocop:todo Style/Documentation
    self.table_name = 'plate_purposes'
    self.inheritance_column = nil
  end

  def conversions
    [
      ['ILB_STD_COVARIS', ['IlluminaB::CovarisPlatePurpose',  'PlatePurpose::InitialPurpose']],
      ['Shear',          ['IlluminaHtp::CovarisPlatePurpose', 'PlatePurpose::InitialPurpose']],
      ['PF Shear',       ['IlluminaHtp::CovarisPlatePurpose', 'PlatePurpose::InitialPurpose']],
      ['ILC AL Libs',    ['IlluminaC::AlLibsPurpose',        'PlatePurpose::InitialPurpose']],
      ['ILB_STD_PCRXP',  ['IlluminaB::FinalPlatePurpose',    'IlluminaHtp::FinalPlatePurpose']],
      ['ILB_STD_PCRRXP', ['IlluminaB::FinalPlatePurpose',    'IlluminaHtp::FinalPlatePurpose']],
      ['ILB_STD_INPUT',  ['IlluminaB::StockPlatePurpose',    'IlluminaHtp::StockPlatePurpose']],
      ['ILB_STD_STOCK',  ['IlluminaB::StockTubePurpose',     'IlluminaHtp::StockTubePurpose']]
    ]
  end

  def up
    ActiveRecord::Base.transaction do
      conversions.each do |name, (old_type, new_type)|
        purpose = Purpose.find_by(name: name)
        unless purpose.type == old_type
          raise StandardError, "Unexpected class for #{name}: #{purpose.type} (expected #{old_type})"
        end

        purpose.update!(type: new_type)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      conversions.each do |name, (old_type, new_type)|
        purpose = Purpose.find_by(name: name)
        unless purpose.type == new_type
          raise StandardError, "Unexpected class for #{name}: #{purpose.type} (expected #{new_type})"
        end

        purpose.update!(type: old_type)
      end
    end
  end
end
