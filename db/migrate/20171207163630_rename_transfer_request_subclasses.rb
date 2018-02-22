# frozen_string_literal: true

class RenameTransferRequestSubclasses < ActiveRecord::Migration[5.1]
  class TransferRequest < ApplicationRecord
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
        TransferRequest.where(sti_type: old_type).update_all(sti_type: new_type) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      RENAME.each do |old_type, new_type|
        TransferRequest.where(sti_type: new_type).update_all(sti_type: old_type) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
