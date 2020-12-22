# frozen_string_literal: true

class DuplicateRequestsTable < ActiveRecord::Migration[5.1] # rubocop:todo Style/Documentation
  TRANSFER_REQUEST_CLASSES = '
    "TransferRequest",
    "CherrypickRequest",
    "PacBioSamplePrepRequest::Initial",
    "TransferRequest::InitialTransfer",
    "TransferRequest::InitialDownstream",
    "CherrypickForFluidigmRequest",
    "CherrypickForPulldownRequest"'

  def up
    ActiveRecord::Base.connection.execute('CREATE TABLE transfer_requests LIKE requests')
    ActiveRecord::Base.connection.execute("INSERT transfer_requests SELECT * FROM requests WHERE sti_type IN (#{TRANSFER_REQUEST_CLASSES})")
  end

  def down
    drop_table :transfer_requests
  end
end
