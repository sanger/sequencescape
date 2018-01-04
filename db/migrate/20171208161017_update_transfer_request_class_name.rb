# frozen_string_literal: true

class UpdateTransferRequestClassName < ActiveRecord::Migration[5.1]
  TRANSFER_REQUEST_CLASSES = {
    'TransferRequest' => :standard,
    'CherrypickRequest' => :standard,
    'PacBioSamplePrepRequest::Initial' => :pacbio_initial,
    'TransferRequest::InitialTransfer' => :initial,
    'TransferRequest::InitialDownstream' => :initial_downstream,
    'CherrypickForFluidigmRequest' => :standard,
    'CherrypickForPulldownRequest' => :standard
  }.freeze

  class RequestType < ApplicationRecord
    self.table_name = 'request_types'
  end

  class PlatePurposeRelationship < ApplicationRecord
    self.table_name = 'plate_purpose_relationships'
    enum transfer_request_class_name: [:standard, :initial, :initial_downstream, :pacbio_initial]
  end

  def change
    ActiveRecord::Base.transaction do
      rts = Hash[RequestType.where(request_class_name: TRANSFER_REQUEST_CLASSES.keys).pluck(:id, :request_class_name)]
      PlatePurposeRelationship.all.each do |relationship|
        relationship.transfer_request_class_name = TRANSFER_REQUEST_CLASSES[rts[relationship.transfer_request_type_id]]
        relationship.save!
      end
    end
  end
end
