# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class EliminateUnnecessaryPlatePurposeClasses < ActiveRecord::Migration
  class Purpose < ActiveRecord::Base
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
        raise StandardError, "Unexpected class for #{name}: #{purpose.type} (expected #{old_type})" unless purpose.type == old_type
        purpose.update_attributes!(type: new_type)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      conversions.each do |name, (old_type, new_type)|
        purpose = Purpose.find_by(name: name)
        raise StandardError, "Unexpected class for #{name}: #{purpose.type} (expected #{new_type})" unless purpose.type == new_type
        purpose.update_attributes!(type: old_type)
      end
    end
  end
end
