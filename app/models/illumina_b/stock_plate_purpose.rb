# Follows same structure as the Pulldown stock plate purpose implimentation.
# As it satands, this class is unecessary, keeping it here for reasons of clarity.
# Keeps the two pipelines distinct.
class IlluminaB::StockPlatePurpose < PlatePurpose
  include PlatePurpose::Stock
end
