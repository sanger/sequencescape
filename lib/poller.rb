# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011 Genome Research Ltd.
# !/usr/bin/env ruby
# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush
STDERR.sync = true; STDERR.flush

# Try to Load Merb
merb_init_file = File.expand_path(File.dirname(__FILE__) + '/../config/merb_init')
if File.exist? merb_init_file
  require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
  # need this because of the CWD
  Merb.root = MERB_ROOT
  require merb_init_file
else
  # Load Rails
  Rails.root ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
  require File.join(Rails.root, 'config', 'boot')
  require File.join(Rails.root, 'config', 'environment')
end

# Load ActiveMessaging processors
# ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start
