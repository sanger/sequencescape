# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

# Searching is really a behaviour separate from the thing you are search against.  For instance, with
# a call to Asset.all you find all assets; except if we removed the asset hierarchy you do not get a search
# across all of the models that made it up.  Instead you want a SearchForAsset model that does the correct
# search behaviour for you.  Well, this is the base for that.
#
# You must implement a 'scope' method that takes a hash of the parameters as a parameter and returns a
# named scope like object (i.e. something the calling code can then call first, last, all or paginate on).
# It is not your search implementations responsibility to decide how many things are being searched for.
class Search < ApplicationRecord
  include Uuid::Uuidable

  validates_presence_of :name
  validates_uniqueness_of :name
  serialize :default_parameters, Hash
end
