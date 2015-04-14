#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
