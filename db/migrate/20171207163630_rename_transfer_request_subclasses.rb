# frozen_string_literal: true

class RenameTransferRequestSubclasses < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  class TransferRequest < ApplicationRecord # rubocop:todo Style/Documentation
    self.table_name = 'transfer_requests'
  end

  RENAME = {
    # old => new
    'CherrypickRequest' => 'TransferRequest::Standard',
    'CherrypickForFluidigmRequest' => 'TransferRequest::Standard',
    'CherrypickForPulldownRequest' => 'TransferRequest::Standard',
    'TransferRequest' => 'TransferRequest::Standard',
    'PacBioSamplePrepRequest::Initial' => 'TransferRequest::PacbioInitial',
    'TransferRequest::InitialTransfer' => 'TransferRequest::Initial'
  }.freeze

  def up
    ActiveRecord::Base.transaction do
      RENAME.each do |old_type, new_type|
        TransferRequest.where(sti_type: old_type).update_all(sti_type: new_type)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      RENAME.each do |old_type, new_type|
        TransferRequest.where(sti_type: new_type).update_all(sti_type: old_type)
      end
    end
  end
end
