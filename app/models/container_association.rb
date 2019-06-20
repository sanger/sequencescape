# This block is disabled when we have the labware table present as part of the AssetRefactor
# Ie. This is what will happens now
AssetRefactor.when_not_refactored do
  # This class allows plates to be associated with wells. It was initially more flexible
  # but that flexibility has not been used and has resulted in complications elsewhere.
  class ContainerAssociation < ApplicationRecord
    # The column names are a bit confusing here, as they predate the association being restricted to plates and
    # wells. I'm holding off renaming the columns at the moment, as this will be revisited as part of the
    # labware/receptacle refactor
    belongs_to :plate, inverse_of: :container_associations, foreign_key: :container_id
    belongs_to :well, inverse_of: :container_association, foreign_key: :content_id
  end
end
