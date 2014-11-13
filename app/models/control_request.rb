class ControlRequest < Request
  include Request::HasNoTargetAsset
  include Api::Messages::FlowcellIO::LaneExtensions
end
