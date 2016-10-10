# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.


# This file extends the Rails 2.3 excpetions to include some of those added in later versions
# It can be removed following the rails upgrade

class ActiveRecord::RecordNotDestroyed < ActiveRecord::ActiveRecordError
end
