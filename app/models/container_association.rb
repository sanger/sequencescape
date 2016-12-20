# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

# This class allows plates to be associated with wells. It was initially more flexible
# but that flexibility has not been used and has resulted in complications elsewhere.
class ContainerAssociation < ActiveRecord::Base
  # The column names are a bit confusing here, as they predate the association being restricted to plates and
  # wells. I'm holding off renaming the columns at the moment, as this will be revisited as part of the
  # labware/receptacle refactor
  belongs_to :plate, class_name: "Plate", inverse_of: :container_associations, foreign_key: :container_id
  belongs_to :well, class_name: "Well", inverse_of: :container_association, foreign_key: :content_id
end
