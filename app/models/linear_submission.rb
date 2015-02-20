#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
# this class it simplified version of Submission which is just a chain of request types
# without any choices
class LinearSubmission < Order
  include Submission::LinearRequestGraph

  def request_type_ids=(id_list)
    self.request_type_ids_list = id_list.map {|i| [i] }
  end

  def request_type_ids
    request_type_ids_list.map(&:first)
  end
end
