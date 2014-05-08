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

