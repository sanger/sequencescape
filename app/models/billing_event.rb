# = Billing Events
#
# A BillingEvent is an abstract event to record when a charge (or a matching refund) has
# been made for a particular laboratory service.
#
# The primary interface is intended for remote invocation via the Projects::BillingEventsController
class BillingEvent < ActiveRecord::Base
  include Api::BillingEventIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable


  belongs_to :project
  belongs_to :request

  validates_presence_of :kind, :entry_date, :reference
  validates_presence_of :created_by
  validates_presence_of :project
  validates_presence_of :quantity
  validates_presence_of :request

  validates_numericality_of :quantity

#  validates_uniqueness_of :reference, :if => :charge?
#  validates_uniqueness_of :reference, :if => :charge_internally?

  named_scope :charged_to_project, { :conditions => { :kind => 'charge' } }
  named_scope :charged_internally, { :conditions => { :kind => 'charge_internally' } }
  named_scope :refunded_to_project, { :conditions => { :kind => 'refund' } }
  named_scope :for_reference, lambda { |reference| { :conditions => { :reference => reference } } }

  named_scope :related_to_reference, lambda { |reference| { :conditions => [ 'reference LIKE ?', "#{reference}%" ] } }
  named_scope :only_these_kinds, lambda { |*kinds| { :conditions => { :kind => kinds } } }

  def self.charge_for_reference(ref)
    self.charged_to_project.for_reference(ref).first
  end

  def self.charge_internally_for_reference(ref)
    self.charged_internally.for_reference(ref).first
  end

  def self.refunds_for_reference(ref)
    self.refunded_to_project.for_reference(ref).all
  end

  #uniqueness of [reference , kind] , validate_uniqueness doesn't work-> see "still test"
  validate :unique_charge_reference, :if => :charge?
  validate :unique_internal_charge_reference, :if => :charge_internally?

  def unique_charge_reference
    match = self.class.charge_for_reference(self.reference)
    errors.add_to_base("Reference #{reference} as already a charge billing event") if match and match != self
  end
  private :unique_charge_reference

  def unique_internal_charge_reference
    match = self.class.charge_internally_for_reference(reference)
    errors.add_to_base("Reference #{reference} as already a charge_internally billing event") if match and match != self
  end
  private :unique_internal_charge_reference

  before_validation :prevent_invalid_refunds, :on => :create, :if => :refund?
  def prevent_invalid_refunds
    # Do not allow refunds for non-existent charges
    matching_charge = BillingEvent.charge_for_reference(self.reference)
    errors.add_to_base("billing_events.exceptions.uncharged_refund") if matching_charge.nil?
    raise BillingException::UnchargedRefund.new(I18n.t("billing_events.exceptions.uncharged_refund")) if matching_charge.nil?

    # Do not allow refunding more if all the refunds are in
    if matching_charge.quantity_left_to_refund <= 0
      errors.add_to_base("billing_events.exceptions.duplicate_refund")
      raise BillingException::DuplicateRefund.new(I18n.t("billing_events.exceptions.duplicate_refund"))
    end

    # Do not allow refunding a quantity more than amount available to refund
    if matching_charge.quantity_left_to_refund < self.quantity
      errors.add_to_base("billing_events.exceptions.over_refund")
      raise BillingException::OverRefund.new(I18n.t("billing_events.exceptions.over_refund", :refunds => matching_charge.quantity_left_to_refund))
    end
  end
  private :prevent_invalid_refunds

  before_validation :on => :create do |record|
    record.entry_date = Time.now
  end

  # charge? returns true if the BillingEvent is a charge (debit) made against the project.
  def charge?
    self.kind == "charge"
  end

  # charge_internally? returns true if the BillingEvent is an internal charge
  def charge_internally?
    self.kind == "charge_internally"
  end

  # refund? returns true if the BillingEvent is a refund (credit) made against the project
  def refund?
    self.kind == "refund"
  end

  # quantity_refunded returns the number of refunds that a charge has received.
  # It will return nil if called on a refund.
  def quantity_refunded
    return nil unless charge?
    BillingEvent.refunded_to_project.for_reference(self.reference).sum(:quantity)
  end

  # quantity_left_to_refund returns the number of refunds that a charge can still accept.
  # It will return nil if called on a refund.
  def quantity_left_to_refund
    return nil unless charge?
    charged  = BillingEvent.charged_to_project.for_reference(self.reference).sum(:quantity)
    refunded = BillingEvent.refunded_to_project.for_reference(self.reference).sum(:quantity)
    charged - refunded
  end

  def self.build_reference(request, aliquot_info=nil)
    aliquot_indice = aliquot_info.try(:indice) || 1
    reference = "R#{request.id}"
    # We need to have a unique reference for every aliquot within the same request
    # so we had the aliquot number in it.
    # However, in order to be able to refund billing event generated with the previous scheme
    # (.i.e data already in the database before we change this method)
    # we don't append anything when it's 1
    reference += "/#{aliquot_indice}" if aliquot_indice>1
    reference
  end

  class << self
    def bill_projects_for(request)
      map_for_each_aliquot(request) do |aliquot_info|
        reference = self.build_reference(request, aliquot_info)
        raise BillingException::DuplicateCharge if self.charge_for_reference(reference).present?
        construct_from_request("charge", "passed", request, aliquot_info).tap do |billing_event|
          billing_event.save!
        end
      end
    end
    alias_method(:generate_pass_event, :bill_projects_for)

    def bill_internally_for(request)
      map_for_each_aliquot(request) do |aliquot_info|
        reference = self.build_reference(request, aliquot_info)
        raise BillingException::DuplicateChargeInternally if self.charge_internally_for_reference(reference).present?
        construct_internal_charge(request, aliquot_info, self.cancel_charged_event_by_reference(reference))
      end
    end
    alias_method(:generate_fail_event, :bill_internally_for)

    def refund_projects_for(request)
      map_for_each_aliquot(request) do |aliquot_info|
        reference     = self.build_reference(request, aliquot_info)
        charged_event = self.charge_for_reference(reference) or raise BillingException::IllegalRefund
        construct_internal_charge(request, aliquot_info, construct_refund(charged_event))
      end
    end

    def cancel_charged_event_by_reference(reference)
      construct_refund(BillingEvent.charge_for_reference(reference))
    end

    def change_decision_refund(reference, description, user)
      construct_refund(BillingEvent.charge_for_reference(reference)) do |billing_event|
        billing_event.description = description
        billing_event.created_by  = user
      end
    end
  end

  class << self
    def construct_from_request(kind, event_type, request, aliquot_info, entry_date=Time.now)
      description = "#{request.request_type.name} #{event_type}"
      #TODO create on event per Aliquot
      project_id = request.initial_project_id || aliquot_info.aliquot.try(:project_id)

      self.new :kind => kind,
        :reference => self.build_reference(request, aliquot_info),
        :project_id => project_id,
        :entry_date => entry_date,
        :created_by => request.user ? request.user.name : "Unknown",
        :description => description,
        :quantity    => 1.0/aliquot_info.number,
        :request    => request
    end
    private :construct_from_request

    def map_for_each_aliquot(request, &block)
      aliquots = request.asset.try(:aliquots)
      aliquots = [nil]  if aliquots.blank?
      number_of_aliquots = aliquots.size
      aliquots.each_with_index.map do |a,i|
        info = OpenStruct.new(:aliquot => a, :indice => i+1, :number => number_of_aliquots)
        block.call(info)
      end
    end
    private :map_for_each_aliquot

    def construct_internal_charge(request, aliquot_info, refund)
      construct_from_request("charge_internally", "failed", request, aliquot_info).tap do |billing_event|
        billing_event.quantity = refund.quantity if refund.present?
        billing_event.save!
      end
    end
    private :construct_internal_charge

    def construct_refund(charged_event, &block)
      return nil if charged_event.nil?
      self.create(charged_event.attributes.merge(
        'kind'       => 'refund',
        'entry_date' => Time.now,
        'quantity'   => charged_event.quantity_left_to_refund
      ), &block)
    end
    private :construct_refund
  end
end
