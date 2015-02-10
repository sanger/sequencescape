#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class SingleRequestSubmission < Order
  def request_type_id=(request_type_id)
    request_type_ids_list = [[request_type_id]]
  end

  def request_type_id
    request_type_ids_list.first.first
  end
end
