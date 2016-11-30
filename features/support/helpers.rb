# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
def fetch_table(selector)
  find(selector).all('tr').map { |row| row.all('th,td').map { |cell| cell.text.squish } }
end

begin
  require 'pry'
rescue  LoadError => exception

end
