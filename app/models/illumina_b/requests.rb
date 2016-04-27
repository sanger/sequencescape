#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.

module IlluminaB::Requests

  class StdLibraryRequest < Request::LibraryCreation
    fragment_size_details(:no_default, :no_default)
  end

end
