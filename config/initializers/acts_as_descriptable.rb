# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
require "#{Rails.root}/lib/acts_as_descriptable/lib/acts_as_descriptable"
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Descriptable)

# require "#{Rails.root}/lib/acts_as_descriptable/lib/acts_as_descriptable"
