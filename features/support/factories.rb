# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

Dir.glob(File.expand_path(File.join(Rails.root, %w{spec factories ** *.rb}))) do |factory_filename|
  require factory_filename
end
