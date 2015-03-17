#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class IlluminaHtp::NormalizedPlatePurpose < PlatePurpose
  include PlatePurpose::RequestAttachment

  write_inheritable_attribute :connect_on, 'passed'
  write_inheritable_attribute :connect_downstream, false
  write_inheritable_attribute :connected_class, IlluminaHtp::Requests::LibraryCompletion

end
