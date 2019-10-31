class TubeRack::Purpose < ::Purpose
  def self.standard_tube_rack
    TubeRack::Purpose.find_by(name: 'TR Stock 96')
  end
end
