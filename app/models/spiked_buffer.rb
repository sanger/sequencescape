# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class SpikedBuffer < LibraryTube
  # The index of a spiked buffer is the first parent library tube.  Note that this does not cover cases where
  # the sti_type is a derivative of LibraryTube, which is actually fine because SpikedBuffer is a LibraryTube
  # and we definitely don't want that in the list.
  has_one_as_child(:index, ->() { where(sti_type: 'LibraryTube').order('id DESC') })

  def library_prep?
    false
  end

  # Before the validations are run on creation we need to ensure that there is at least an aliquot of phiX
  # in this tube.
  before_validation(on: :create) do |record|
    record.aliquots.build(sample: record.class.phiX_sample) if record.aliquots.empty?
  end

  def self.phiX_sample
    Sample.find_by(name: 'phiX_for_spiked_buffers') or raise StandardError, 'Cannot find phiX_for_spiked_buffers sample'
  end

  def percentage_of_index
    return nil unless index
    100 * index.volume / volume
  end

  def transfer(transfer_volume)
    index_volume_to_transfer = index.volume * transfer_volume.to_f / volume # to do before super which modifies self.volume
    super(transfer_volume).tap do |new_asset|
      new_asset.index = index.transfer(index_volume_to_transfer)
    end
  end
end
