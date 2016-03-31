#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015,2016 Genome Research Ltd.


user = User.new(
  :first_name       => 'Admin',
  :last_name        => 'Admin',
  :login            => 'admin',
  :password         => 'admin',
)
user.is_administrator()
user.save(validate: true)
