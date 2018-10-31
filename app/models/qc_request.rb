class QcRequest < CustomerRequest
  include Request::HasNoTargetAsset
end
