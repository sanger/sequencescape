#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
module ActiveRecord::ExtraValidations
  def validates_unassigned(*attrs)
    validates_each(*attrs) { |record, attr, value| record.errors.add(attr, 'cannot be assigned') if value.present? }
  end
end

class ActiveRecord::Base
  extend ActiveRecord::ExtraValidations
end
