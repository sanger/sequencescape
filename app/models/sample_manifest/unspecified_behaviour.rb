# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

# Simple core module to handle options when no type has been specified
# Not valid for actually building manifests, just for rendering forms
module SampleManifest::UnspecifiedBehaviour
  class Core
    def initialize(_manifest)
      # Do nothing
    end

    def acceptable_purposes
      PlatePurpose.for_submissions
    end

    def generate
      raise StandardError, 'UnspecifiedBehaviour can not be used to build manifests'
    end
  end

  class RapidCore < Core
  end
end
