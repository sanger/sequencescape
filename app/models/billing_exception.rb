#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
module BillingException
  class Base < StandardError
  end
  # Raised when a refund is being created but there is no charge event with the same reference
  class UnchargedRefund < Base
  end
  # Raised when a second refund is being created for a charge that has been refunded
  class DuplicateRefund < Base
  end
  # Raised when a refund has a quantity which is more than the original charge has left to refund
  class OverRefund < Base
  end
  # Raised when a second charge is being created for a charge with the same reference
  class DuplicateCharge < Base
  end
  class DuplicateChargeInternally < Base
  end
#rescue BillingException::DuplicateCharge => exception
#rescue BillingException::Base => exception

  IllegalRefund = Class.new(Base)
end

