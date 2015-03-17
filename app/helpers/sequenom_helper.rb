#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module SequenomHelper
  def dropdown_for_steps(field_name)
    select_tag(field_name, options_for_select(SequenomController::STEPS.map(&:name), :select => SequenomController::STEPS.first.name))
  end
end
