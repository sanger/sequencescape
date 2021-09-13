# frozen_string_literal: true
# Cherrypicking describes the transfer of selected samples from one or more plate, onto new
# locations on other plates.
module Cherrypick
  # Various types of error that can occur during cherrypicking
  Error = Class.new(StandardError)
  VolumeError = Class.new(Error)
  ConcentrationError = Class.new(Error)
  AmountError = Class.new(Error)
end
