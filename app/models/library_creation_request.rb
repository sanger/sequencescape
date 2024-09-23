# frozen_string_literal: true

# Used in the old-style (Workflow driven) tube based library creation pipelines
class LibraryCreationRequest < CustomerRequest
  # NOTE: Do not alter the order here:
  #
  # 1. has_metadata :as => Request
  # 2. include Request::LibraryManufacture
  # 3. class RequestOptionsValidator
  #
  # These are dependent upon each other
  has_metadata as: Request do
    # /!\ We don't check the read_length, because we don't know the restriction, that depends on the SequencingRequest
    custom_attribute(:read_length, integer: true) # meaning , so not required but some people want to set it
    custom_attribute(:gigabases_expected, positive_float: true)
  end

  include Request::CustomerResponsibility
  include Request::LibraryManufacture

  # When a library creation request passes it does the default behaviour of a request but also adds the
  # insert size to the aliquots in the target asset and sets the library.  There's a minor complication in that
  # an MX library is also a type of library that might have libraries coming into it, therefore we only update the
  # information that is missing.
  def on_started
    ActiveRecord::Base.transaction do
      super
      transfer_aliquots
      target_asset.aliquots.each do |aliquot|
        aliquot.library ||= target_asset
        aliquot.library_type ||= library_type
        aliquot.insert_size ||= insert_size
        aliquot.save!
      end
    end
  end

  #
  # Passed into cloned aliquots at the beginning of a pipeline to set
  # appropriate options
  #
  #
  # @return [Hash] A hash of aliquot attributes
  #
  def aliquot_attributes
    { study_id: initial_study_id, project_id: initial_project_id, library_type:, insert_size:, request_id: id }
  end
end
