# frozen_string_literal: true
class QcRequest < CustomerRequest
  include Request::HasNoTargetAsset
end
