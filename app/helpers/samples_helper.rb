#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module SamplesHelper
  # Use this wherever you are editing a sample so that you get the sample 'common name' lookup
  # behaviour.  Attach 'data-organism' attribute to the 'common name' and 'taxon ID' fields
  # to get them updated.
  def organism_validation_javascript
    javascript_include_tag('organism_validation')
  end

end
