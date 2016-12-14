# Input Plate purposes are the initial stock plates passing into
# external piplines. They have special behaviour governing their state.
class PlatePurpose::Input < PlatePurpose
  include PlatePurpose::Stock
end
