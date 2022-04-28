# frozen_string_literal: true
# A ControlPlate is a {Plate} containing control samples
# Often these controls may be used multiple times as part of Pipeline QC.
# A {Sample} with control set to true, does not necessarily enter the pipleine
# via a ControlPlate.
#
# The main differences control plates show from standard plates is:
# - When Cherrypicking via a robot with {Robot::Verification::SourceDestControlBeds} such as the Hamilton they
#   are asigned a seperate bed to reduce the risk of contamination
class ControlPlate < Plate
  # When Cherrypicking, especially on the Hamilton, control plates get placed
  # on a seperate bed. This is currently set to true. However, as the behaviouir needs to be explicitly enabled
  # in the Hamilton software, we may need to make this conditional in the future.
  # @return [Boolean] currently returns true.
  def pick_as_control?
    true
  end
end
