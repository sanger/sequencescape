# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

# The following module is included where we have deprecated behaviours that rely on sample or request.
module Aliquot::DeprecatedBehaviours
  module Request
    def tag_number
      tag.try(:map_id) || ''
    end
    deprecate :tag_number

    # tags and tag have been moved to the appropriate assets.
    # I don't think that they are used anywhere else apart
    # from the batch xml and can therefore probably be removed.
    # ---
    # Nope, they are used all over the place.
    def tag
      target_asset.primary_aliquot.try(:tag)
    end
    deprecate :tag

    delegate :tags, to: :asset
    deprecate :tags
    # ---

    def sample_name?
      samples.present?
    end
    deprecate :sample_name?

    def sample_name(default = nil)
      # return the name of the underlying samples
      # used mainly for compatibility with the old codebase
      # # default is used if no smaple
      # # block is used to aggregate the samples
      case
      when samples.size == 0 then default
      when samples.size == 1 then samples.first.name
      when block_given?      then yield(samples)
      else                        samples.map(&:name).join(' | ')
      end
    end
    deprecate :sample_name
  end
end
