#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module Pipeline::RequestsInStorage
  def ready_in_storage
    send((proxy_owner.group_by_parent ? :holder_located : :located), proxy_owner.location_id)
  end
end
