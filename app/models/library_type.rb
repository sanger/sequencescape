#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class LibraryType < ActiveRecord::Base

  validates_presence_of :name

  has_many :library_types_request_types, :inverse_of=> :library_type
  has_many :request_types, :through => :library_types_request_types

end
