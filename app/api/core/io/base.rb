# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class ::Core::Io::Base
  extend ::Core::Logging
  extend ::Core::Benchmarking
  extend ::Core::Io::Base::EagerLoadingBehaviour
  extend ::Core::Io::Base::JsonFormattingBehaviour

  class << self
    def map_parameters_to_attributes(*_args)
      {}
    end
    private :map_parameters_to_attributes
  end
end
