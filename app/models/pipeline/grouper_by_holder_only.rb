# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class Pipeline::GroupByHolderOnly
  include Pipeline::Grouper

  def call(conditions, variables, group)
    conditions << 'tca.container_id=?'
    variables  << group.to_i
  end
  private :call

  def grouping
    'tca.container_id'
  end
  private :grouping
end
