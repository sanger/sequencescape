# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class BarcodePrinterType < ActiveRecord::Base
  has_many :barcode_printers
  validates_presence_of :name
  validates_uniqueness_of :name, on: :create, message: 'already in use'
  # printer_type_id is used by the perl script printing service to decide on the positioning of information on the label
end
