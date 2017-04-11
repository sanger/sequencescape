# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

class ::Io::MultiplexedLibraryTube < ::Io::LibraryTube
  set_model_for_input(::MultiplexedLibraryTube)
  set_json_root(:multiplexed_library_tube)

  define_attribute_and_json_mapping('')
  # TODO: Find an efficient way to display state as it kills transfers_to_tubes for plates!
  #  define_attribute_and_json_mapping(%Q{
  #    state  => state
  #  })
end
