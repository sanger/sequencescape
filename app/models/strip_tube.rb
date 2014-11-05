##
# StripTubes can be thought of as long skinny plates.
# Unlike normal plates they can be kept in a rack.
# Strip tubes don't get a barcode assigned upfront and
# instead get assigned it later.
class StripTube < Plate
  contained_by :asset_rack

  self.prefix = 'LS'
end
