#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddCoreProducts < ActiveRecord::Migration

  PRODUCTS = [
    'MWGS',
    'PWGS',
    'ISC',
    'HSqX',
    'ReISC',
    'PacBio',
    'Fluidigm'
  ]

  def self.up
    ActiveRecord::Base.transaction do
      PRODUCTS.each do |name|
        Product.create!(:name=>name)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PRODUCTS.each do |name|
        Product.find_by_name(name).delete
      end
    end
  end
end
