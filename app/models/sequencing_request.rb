# encoding: utf-8

class SequencingRequest < CustomerRequest
  extend Request::AccessioningRequired
  include Api::Messages::FlowcellIO::LaneExtensions

  class_attribute :flowcell_identifier

  self.sequencing = true
  self.flowcell_identifier = 'Chip Barcode'

  has_metadata as: Request do
    # redundant with library creation , but THEY are using it .
    custom_attribute(:fragment_size_required_from, integer: true, minimum: 1)
    custom_attribute(:fragment_size_required_to, integer: true, minimum: 1)

    custom_attribute(:read_length, integer: true, validator: true, required: true, selection: true)
  end

  include Request::CustomerResponsibility

  before_validation :clear_cross_projects
  def clear_cross_projects
    self.initial_project = nil if submission.try(:cross_project?)
    self.initial_study   = nil if submission.try(:cross_study?)
  end
  private :clear_cross_projects

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate :fragment_size_required_from, :fragment_size_required_to, to: :target
    validates_numericality_of :fragment_size_required_from, integer_only: true, greater_than: 0, allow_nil: true
    validates_numericality_of :fragment_size_required_to, integer_only: true, greater_than: 0, allow_nil: true
  end

  def on_started
    super
    transfer_aliquots
  end

  def order=(_)
    # Do nothing
  end

  # Returns true if a request is read for batching
  def ready?
    # Reject any requests with missing or empty assets.
    # We use most tagged aliquot here, as its already loaded.
    return false if asset.nil? || asset.most_tagged_aliquot.nil?
    # Rejects any assets which haven't been scanned in
    return false if asset.scanned_in_date.blank?

    # It's ready if I don't have any lib creation requests or if all my lib creation requests are closed and
    # at least one of them is in 'passed' status
    upstream_requests.empty? ||
      upstream_requests.all?(&:closed?) &&
        upstream_requests.any?(&:passed?)
  end

  def self.delegate_validator
    SequencingRequest::RequestOptionsValidator
  end

  def concentration
    return ' ' if lab_events_for_batch(batch).empty?

    conc = lab_events_for_batch(batch).first.descriptor_value('Concentration')
    return "#{conc}μl" if conc.present?

    dna = lab_events_for_batch(batch).first.descriptor_value('DNA Volume')
    rsb = lab_events_for_batch(batch).first.descriptor_value('RSB Volume')
    "#{dna}μl DNA in #{rsb}μl RSB"
  end

  def billing_product_identifier
    request_metadata.read_length
  end
end
