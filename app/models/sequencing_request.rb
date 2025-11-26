# encoding: utf-8
# frozen_string_literal: true

class SequencingRequest < CustomerRequest
  extend Request::AccessioningRequired
  include Api::Messages::FlowcellIo::LaneExtensions

  class_attribute :flowcell_identifier

  self.sequencing = true
  self.flowcell_identifier = 'Chip Barcode'

  has_metadata as: Request do
    # redundant with library creation , but THEY are using it .
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)

    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
    custom_attribute(:requested_flowcell_type, required: false, validator: true, selection: true, on: :create)
  end

  include Request::CustomerResponsibility
  include Request::SampleCompoundAliquotTransfer

  before_validation :clear_cross_projects
  def clear_cross_projects
    self.initial_project = nil if submission.try(:cross_project?)
    self.initial_study = nil if submission.try(:cross_study?)
  end
  private :clear_cross_projects

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate :fragment_size_required_from, :fragment_size_required_to, to: :target
    validates :fragment_size_required_from, numericality: { integer_only: true, greater_than: 0, allow_nil: true }
    validates :fragment_size_required_to, numericality: { integer_only: true, greater_than: 0, allow_nil: true }
  end

  def on_started
    super

    compound_samples_needed? ? transfer_aliquots_into_compound_sample_aliquots : transfer_aliquots
  end

  def order=(_)
    # Do nothing
  end

  # Returns true if a request is ready for batching
  def ready?
    # Reject any requests with missing or empty assets.
    # We use most tagged aliquot here, as its already loaded.
    return false if asset.nil? || asset.most_tagged_aliquot.nil?

    # Rejects any assets which haven't been scanned in
    return false if asset.scanned_in_date.blank?

    # It's ready if I don't have any lib creation requests or if all my lib creation requests are closed and
    # at least one of them is in 'passed' status
    upstream_requests.empty? || (upstream_requests.all?(&:closed?) && upstream_requests.any?(&:passed?))
  end

  def self.delegate_validator
    SequencingRequest::RequestOptionsValidator
  end

  def concentration
    event = most_recent_event_named('Specify Dilution Volume')
    return ' ' if event.nil?

    concentration = event.descriptor_value('Concentration')
    return "#{concentration}μl" if concentration.present?

    dna = event.descriptor_value('DNA Volume')
    rsb = event.descriptor_value('RSB Volume')
    "#{dna}μl DNA in #{rsb}μl RSB"
  end
end
