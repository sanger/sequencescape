# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class LibraryType < ApplicationRecord
  validates_presence_of :name

  scope :alphabetical, ->() { order(:name) }

  has_many :library_types_request_types, inverse_of: :library_type, dependent: :destroy
  has_many :request_types, through: :library_types_request_types

end
