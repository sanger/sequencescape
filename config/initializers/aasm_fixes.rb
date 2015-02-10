#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
# AASM isn't consistent with the Rails use of '!'.  So, I give you ...
module AASM::ClassMethods
  def aasm_event_with_exception_raising(name, options = {}, &block)
    aasm_event_without_exception_raising(name, options, &block)
    define_method("#{name.to_s}!") do |*args|
      aasm_fire_event(name, true, *args) or raise ActiveRecord::RecordInvalid, self
    end
  end
  alias_method_chain(:aasm_event, :exception_raising)
end
