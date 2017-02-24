# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module FieldInfosHelper
  def field_info_id(path, field)
    path = path.clone
    return field if path.empty?
    first = path.shift
    to_bracketize = path + [field.key] # , "value"]
    to_join = [first] + to_bracketize.map { |w| "[#{w}]" }
    to_join.join
  end

  def field_info_label(path, field)
    (path + [field.key]).join('_')
  end
end
