#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
module ModelExtensions::Robot

  def json_for_properties
    Hash[robot_properties.map {|prop| [prop.key,prop.value] }]
  end

  private

end
