# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class Barcode
  require 'sanger_barcode_format'
  require 'sanger_barcode_format/legacy_methods'
  extend SBCF::LegacyMethods

  # What?! Where is everything?

  # Don't worry, your usual methods are available, however it is probably
  # better to take a look over at:
  # https://github.com/sanger/sanger_barcode_format
  # Or the docs at:
  # http://www.rubydoc.info/github/sanger/sanger_barcode_format/development/

  # Extracted from the sanger_barcode_format Readme:
  # # Using builders
  # barcode = SBCF::SangerBarcode.from_human('DN12345R')
  # barcode = SBCF::SangerBarcode.from_machine(4500101234757)
  # barcode = SBCF::SangerBarcode.from_prefix_and_number('EG',123)

  # # Using standard initialize
  # barcode = SBCF::SangerBarcode.new(prefix:'EG',number:123)
  # barcode = SBCF::SangerBarcode.new(human_barcode:'DN12345R')
  # barcode = SBCF::SangerBarcode.new(hmachine_barcode:4500101234757)

  # # Converting between formats
  # barcode = SBCF::SangerBarcode.new(prefix:'PR',number:1234)
  # barcode.human_barcode # => PR1234K'
  # barcode.machine_barcode # => 4500001234757

  # # Pulling out components
  # barcode = SBCF::SangerBarcode.new(machine_barcode: 4500001234757)
  # barcode.prefix.human # => 'PR'
  # barcode.checksum.human # => 'K'
end
