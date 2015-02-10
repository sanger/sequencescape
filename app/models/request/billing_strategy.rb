#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
# This is the billing standardised billing strategy, which actually does nothing because all of that
# is handled externally to most request types.  However, if you have request classes that need to do something
# unusual (like Pulldown requests as they are not batched) then override these methods in your class.
module Request::BillingStrategy
  # This is called when the project should be billed for the request.
  def charge_to_project

  end

  # This is called when the charge for the request should be absorbed internally.
  def charge_internally

  end

  # This is called when the project should be refunded for this request.
  def refund_project

  end
end
