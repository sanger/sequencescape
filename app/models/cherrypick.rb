module Cherrypick
  # Various types of error that can occur during cherrypicking
  Error              = Class.new(StandardError)
  VolumeError        = Class.new(Error)
  ConcentrationError = Class.new(Error)
  AmountError        = Class.new(Error)
end
