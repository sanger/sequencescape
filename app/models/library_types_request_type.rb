# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class LibraryTypesRequestType < ApplicationRecord
  belongs_to :library_type, inverse_of: :library_types_request_types
  belongs_to :request_type, inverse_of: :library_types_request_types
end
