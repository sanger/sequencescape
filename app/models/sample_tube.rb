# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class SampleTube < Tube
  include Api::SampleTubeIO::Extensions
  include ModelExtensions::SampleTube
  include StandardNamedScopes

  after_create do |record|
    record.barcode = AssetBarcode.new_barcode           if record.barcode.blank?
    record.name    = record.primary_aliquot.sample.name if record.name.blank? and not record.primary_aliquot.try(:sample).nil?

    record.save! if record.barcode_changed? or record.name_changed?
  end

  # All instances are labelled 'SampleTube', unless otherwise specified
  before_validation do |record|
    record.label = 'SampleTube' if record.label.blank?
  end

  def created_with_request_options
    {}
  end

  def can_be_created?
    true
  end
end
