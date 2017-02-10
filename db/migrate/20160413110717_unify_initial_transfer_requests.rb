# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
require './lib/request_class_deprecator'

class UnifyInitialTransferRequests < ActiveRecord::Migration
  include RequestClassDeprecator

  def up
    ActiveRecord::Base.transaction do
      # Create Initial Transfer Request TYpe for future Use
      initial_transfer = RequestType.create!(
        name: 'Initial Transfer', key: 'initial_transfer', order: 1,
        asset_type: 'Asset', multiples_allowed: false,
        request_class_name: 'TransferRequest::InitialTransfer', morphology: RequestType::CONVERGENT,
        for_multiplexing: 0, billable: 0,
        request_purpose: RequestPurpose.find_by(key: 'internal')
      )

      deprecate_class('IlluminaB::Requests::InputToCovaris', new_type: initial_transfer)
      deprecate_class('IlluminaC::Requests::InitialTransfer', new_type: initial_transfer)
      deprecate_class('IlluminaC::Requests::StockToAlLibsTagged', new_type: initial_transfer)
      deprecate_class('IlluminaHtp::Requests::CherrypickedToShear', new_type: initial_transfer)
      deprecate_class('Pulldown::Requests::StockToCovaris', new_type: initial_transfer)
    end
  end

  def down
  end
end
