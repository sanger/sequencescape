class ControlRequest < Request
  include Request::HasNoTargetAsset
  include Api::Messages::FlowcellIO::ControlLaneExtensions
end
