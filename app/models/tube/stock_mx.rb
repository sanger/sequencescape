# frozen_string_literal: true
# Used in the legacy {Pipeline pipelines} and in non-pipeline processes such as
# {Pooling}. Represents one or more tagged libraries in a tube together, which have
# either not been normalised for sequencing, or are being held in reserve.
# @note As of 2019-10-01 only used for 'Standard MX' and 'Tag Stock-MX' tubes (Gatekeeper)
class Tube::StockMx < Tube::Purpose
  self.state_changer = StateChanger::StockTube
end
