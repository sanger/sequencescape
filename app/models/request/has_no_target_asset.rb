# frozen_string_literal: true
# Some requests, notably DNA QC, do not actually transfer to a target asset but work on the source
# one.  In this case there are certain things that are not permitted.
module Request::HasNoTargetAsset
  def on_started
    # Do not transfer the aliquots as there is no target asset
  end
end
