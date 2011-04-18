# = Billing Events
#
# A BillingEvent is an abstract event to record when a charge (or a matching refund) has
# been made for a particular laboratory service.
#
# The primary interface is intended for remote invocation via the Projects::BillingEventsController
class BillingEvent < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable


  belongs_to :project
  belongs_to :request
  
  validates_presence_of :kind, :entry_date, :reference
  validates_presence_of :created_by
  validates_presence_of :project
  validates_presence_of :quantity

  validates_numericality_of :quantity
  
  named_scope :including_associations_for_json, { :include => [ :uuid_object, { :project =>[ { :project_metadata => :budget_division }, :uuid_object ] }, { :request => [ :request_metadata, :request_type, :uuid_object ] } ] }

#  validates_uniqueness_of :reference, :if => :charge?
#  validates_uniqueness_of :reference, :if => :charge_internally? 

  named_scope :related_to_reference, lambda { |reference| { :conditions => [ 'reference LIKE ?', "#{reference}%" ] } }
  named_scope :only_these_kinds, lambda { |*kinds| { :conditions => { :kind => kinds } } }

  #uniqueness of [reference , kind] , validate_uniqueness doesn't work-> see "still test"
  def validate
      case
      when charge?
        match = self.class.charge_for_reference(self.reference)
        if match and match != self
          errors.add_to_base("Reference #{reference} as already a charge billing event")
        end
      when charge_internally?
        match = self.class.charge_internally_for_reference(reference)
        if match and match != self
          errors.add_to_base("Reference #{reference} as already a charge_internally billing event")
        end
      end

  end

  def before_validation_on_create #:nodoc:
    self.entry_date = Time.now
    if refund?
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
        raise BillingException::OverRefund.new(I18n.t("billing_events.exceptions.over_refund",
          :refunds => matching_charge.quantity_left_to_refund))
      end

    end
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

  def self.charge_for_reference(ref)
    BillingEvent.find_by_reference_and_kind(ref, "charge")
  end

  def self.charge_internally_for_reference(ref)
    BillingEvent.find_by_reference_and_kind(ref, "charge_internally")
  end

  def self.refunds_for_reference(ref)
    BillingEvent.find_all_by_reference_and_kind(ref, "refund")
  end

  def self.build_reference(request)
    "R#{request.id}"
  end

  def self.construct_from_request(kind, event_type, request, entry_date=Time.now)
    description = "#{request.request_type.name} #{event_type}"

    self.new :kind => kind,
      :reference => self.build_reference(request),
      :project_id => request.project_id,
      :entry_date => entry_date,
      :created_by => request.user ? request.user.name : "Unknown",
      :description => description,
      :request    => request
  end

  def self.generate_pass_event(request)
    reference = BillingEvent.build_reference(request)

    #check if  a billing event already exist
    matching_event = BillingEvent.charge_for_reference(reference)
    raise BillingException::DuplicateCharge if matching_event

    b = construct_from_request("charge", "passed", request)
    b.save!
    b
  end

  def self.generate_fail_event(request)
    reference = BillingEvent.build_reference(request)

    charged_event = BillingEvent.charge_for_reference(reference)
    refund = BillingEvent.cancel_charged_event_by_reference(reference)
    matching_event = BillingEvent.charge_internally_for_reference(reference)
    raise BillingException::DuplicateChargeInternally if matching_event
    b = construct_from_request("charge_internally", "failed", request)
    b.quantity = refund.quantity if refund
    b.save!
    b
  end

  def self.cancel_charged_event_by_reference(reference)
    charged_event = BillingEvent.charge_for_reference(reference)

    if charged_event
      #copy the attributes of event to cancel
      attributes = charged_event.attributes
      attributes["kind"] = "refund"
      attributes["entry_date"] = Time.now
      quantity = charged_event.quantity_left_to_refund
      attributes["quantity"] = quantity

      refund = BillingEvent.create attributes
    end
  end
 
  def self.change_decision_refund(reference, description, user)
    charged_event = BillingEvent.charge_for_reference(reference)

    if charged_event
      #copy the attributes of event to cancel
      attributes = charged_event.attributes
      attributes["kind"] = "refund"
      attributes["entry_date"] = Time.now
      quantity = charged_event.quantity_left_to_refund
      attributes["quantity"] = quantity
      attributes["description"] = description
      attributes["created_by"] = user

      refund = BillingEvent.create attributes
    end
  end

  # quantity_refunded returns the number of refunds that a charge has received.
  # It will return nil if called on a refund.
  def quantity_refunded
    if charge?
      BillingEvent.refunds_for_reference(self.reference)
      refunds_made = BillingEvent.sum('quantity', :conditions => {:reference => self.reference, :kind => "refund"})
    else
      nil
    end
  end

  # quantity_left_to_refund returns the number of refunds that a charge can still accept.
  # It will return nil if called on a refund.
  def quantity_left_to_refund
    if charge?
      BillingEvent.refunds_for_reference(self.reference)
      initially_charged = BillingEvent.charge_for_reference(self.reference).quantity
      refunds_made = BillingEvent.sum('quantity', :conditions => {:reference => self.reference, :kind => "refund"})
      initially_charged - refunds_made
    else
      nil
    end
  end
  
  def self.render_class
    Api::BillingEventIO
  end

end
