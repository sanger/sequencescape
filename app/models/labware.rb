# frozen_string_literal: true

# Labware represents a physical object which moves around the lab.
# It has one or more receptacles.
# This class has been created as part of the {AssetRefactor} when not in
# refactor mode this class is pretty much ignored
class Labware < Asset
  AssetRefactor.when_not_refactored do
    self.table_name = 'assets'
  end

  AssetRefactor.when_refactored do
    include LabwareAssociations
    include Commentable
    include Uuid::Uuidable
    include AssetLink::Associations
    has_many :receptacles, dependent: :restrict_with_exception
    has_many :messengers, as: :target, inverse_of: :target, dependent: :destroy
    has_many :samples, through: :receptacles
  end
end
