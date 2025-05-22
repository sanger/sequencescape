# frozen_string_literal: true

# The purpose of a tube rack is to hold tubes.
# Created to hold the size of the tube rack for use when generating manifests.
class TubeRack::Purpose < Purpose
  self.state_changer = StateChanger::TubeRack

  has_many :sample_manifests, inverse_of: :tube_rack_purpose, dependent: :restrict_with_exception

  # TODO: change to purpose_id
  has_many :tube_racks, foreign_key: :plate_purpose_id, inverse_of: :purpose, dependent: :restrict_with_exception

  def self.standard_tube_rack
    TubeRack::Purpose.find_by(name: 'TR Stock 96')
  end

  def create!(*args, &)
    options = args.extract_options!
    options[:purpose] = self
    options[:size] = size
    target_class.create!(*args, options, &).tap { |tr| tube_racks << tr }
  end
end
