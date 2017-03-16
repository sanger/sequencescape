# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

# This class allows plates to be associated with wells. It was initially more flexible
# but that flexibility has not been used and has resulted in complications elsewhere.
class ContainerAssociation < ActiveRecord::Base
  # Rails doesn't handle through associations very well when single table inheritance is also in play.
  # For example the following:
  # Plate.first.wells.includes(:plate)
  # generates invalid sql, where it attempts to eager_load the container associations. It tries to filter
  # on assets.sti_type, but doesn't join on the assets table.
  # Here we force the join, and ensure everything works as intended. It is also possible to switch to
  # specifying the class_name: 'Asset' on each association, but this has the side effect of disrupting
  # other eager loading as associations aren't specified on Asset.
  # Ideally we should be avoiding using single table inheritance in this manner; this is far from the only
  # place it has caused pain.
  default_scope ->() { includes(:plate, :well) }

  # The column names are a bit confusing here, as they predate the association being restricted to plates and
  # wells. I'm holding off renaming the columns at the moment, as this will be revisited as part of the
  # labware/receptacle refactor
  belongs_to :plate, inverse_of: :container_associations, foreign_key: :container_id
  belongs_to :well, inverse_of: :container_association, foreign_key: :content_id
end
