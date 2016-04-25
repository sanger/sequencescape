#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
# Rack 1.1.3 introduced flooding protection support that needs to be significantly higher for our environment.
# This multiplier is completely arbitrary as we have no rogue clients, except maybe our users!
Rack::Utils.key_space_limit = Rack::Utils.key_space_limit * 20
