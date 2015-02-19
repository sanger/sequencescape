#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
# Some requests, notably DNA QC, do not actually transfer to a target asset but work on the source
# one.  In this case there are certain things that are not permitted.
module Request::HasNoTargetAsset
  def on_started
    # Do not transfer the aliquots as there is no target asset
  end
end
