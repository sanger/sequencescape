# This is the billing strategy for the pulldown requests, which mimics the behaviour of the
# general billing behaviour.
module Request::StandardBillingStrategy
  def charge_to_project
    BillingEvent.bill_projects_for(self) if request_type.billable?
  end

  def charge_internally
    BillingEvent.bill_internally_for(self) if request_type.billable?
  end

  def refund_project
    BillingEvent.refund_projects_for(self) if request_type.billable?
  end
end