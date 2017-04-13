# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require './lib/product_helpers'

[
  ProductHelpers.single_template('Generic'),
  ProductHelpers.single_template('MWGS'),
  ProductHelpers.single_template('PWGS'),
  ProductHelpers.single_template('ISC'),
  ProductHelpers.single_template('HSqX'),
  ProductHelpers.single_template('ReISC'),
  ProductHelpers.single_template('PacBio'),
  ProductHelpers.single_template('Fluidigm'),
  ProductHelpers.single_template('SC'),
  ProductHelpers.single_template('InternalQC'),
  {
    name: 'GenericPCR',
    selection_behaviour: 'LibraryDriven',
    products: {
      nil => 'Generic'
    }
  },
  {
    name: 'GenericNoPCR',
    selection_behaviour: 'LibraryDriven',
    products: {
      nil => 'Generic'
    }
  },
  {
    name: 'ClassicMultiplexed',
    selection_behaviour: 'LibraryDriven',
    products: {
      nil => 'Generic'
    }
  },
  {
    name: 'Manual',
    selection_behaviour: 'Manual',
    products: {
      nil => 'Generic',
      'MWGS' => 'MWGS',
      'PWGS' => 'PWGS',
      'ISC'  => 'ISC',
      'HSqX' => 'HSqX'
    }
  }
].each do |param|
  ProductCatalogue.construct!(param)
end

Product.find_by(name: 'MWGS').product_criteria.create!(stage: 'stock', behaviour: 'Basic', configuration: { total_micrograms: { greater_than: 50 } })
