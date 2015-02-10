#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Io::MultiplexedLibraryCreationRequest < ::Io::LibraryCreationRequest
  set_model_for_input(::MultiplexedLibraryCreationRequest)
  set_json_root(:multiplexed_library_creation_request)
  define_attribute_and_json_mapping('')
end
