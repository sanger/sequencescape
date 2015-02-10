#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class Search::FindModelByName < Search
  validates_presence_of :model_name

  def model
    model_name.constantize
  end
  private :model

  def scope(criteria)
    model.with_name(criteria['name'])
  end
end
