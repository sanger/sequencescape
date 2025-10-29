# frozen_string_literal: true
class ControlRequest < CustomerRequest
  include Request::HasNoTargetAsset
  include Api::Messages::FlowcellIo::ControlLaneExtensions
  include Api::Messages::UseqWaferIo::ControlLaneExtensions
end
