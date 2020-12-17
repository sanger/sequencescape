# frozen_string_literal: true

# Null object for situations where you wish to explicitly indicate you have no
# request. (In contrast to nil, which could too easily result from a bug)
# Added to allow {Pooling} to indicate there should ne no outer request,
# without risking incorrect behaviour if we pass in nil unintentionally.
#
class Request::None
  def submission_id
    nil
  end

  def id
    nil
  end

  # Normal requests can inject attributes into aliquots created by transfer
  # requests associated with the request.
  # In the case of Request::None we return an empty hash, which ensures that no
  # additional attributes are injected
  def aliquot_attributes
    {}
  end
end
