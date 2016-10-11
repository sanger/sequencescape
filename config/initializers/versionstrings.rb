# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012 Genome Research Ltd.
begin
  require 'deployed_version'
rescue LoadError
  module Deployed
    VERSION_ID = 'LOCAL'
    VERSION_STRING = "#{File.split(Rails.root).last.capitalize} LOCAL [#{Rails.env}]"
  end
end
