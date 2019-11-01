# frozen_string_literal: true

# The purpose of a tube rack is to hold tubes.
# Created to hold the size of the tube rack for use when generating manifests.
class TubeRack::Purpose < ::Purpose
  def self.standard_tube_rack
    TubeRack::Purpose.find_by(name: 'TR Stock 96')
  end
end
