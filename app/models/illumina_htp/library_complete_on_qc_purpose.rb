# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class IlluminaHtp::LibraryCompleteOnQcPurpose < PlatePurpose
  include PlatePurpose::Library
  include PlatePurpose::RequestAttachment
  include PlatePurpose::BroadcastLibraryComplete

  self.connect_on = 'qc_complete'
  self.connect_downstream = false
end
