# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class SampleTube < Tube
  include Api::SampleTubeIO::Extensions
  include ModelExtensions::SampleTube
  include StandardNamedScopes

  self.stock_message_template = 'TubeStockResourceIO'

  before_create :generate_barcode, unless: :barcode?
  after_create :generate_name_from_aliquots, unless: :name?

  # All instances are labelled 'SampleTube', unless otherwise specified
  before_validation do |record|
    record.label = 'SampleTube' if record.label.blank?
  end

  def can_be_created?
    true
  end

  private

  def generate_barcode
    self.barcode ||= AssetBarcode.new_barcode
  end

  def generate_name_from_aliquots
    return if name.present? || primary_aliquot.try(:sample).nil?
    self.name = primary_aliquot.sample.name
    save!
  end
end
