# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
# This contains details of the release of the application
# to remove hard coding throughout the application

# Parts of this file could be dynamically rewritten by
# Capistrano task / Git hooks on deployments / commits

require 'ostruct'

RELEASE = OpenStruct.new

RELEASE.api_version = '0.6' # which API ?
