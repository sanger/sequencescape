#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
module Core::References
  # Discards all of the references that this object is keeping to other objects.  This means that
  # all of the objects should be garbage collected, rather than a proportion that are external to an
  # instance of this class.
  def discard_all_references
    instance_variables.each { |name| instance_variable_set(name, nil) }
  end
  private :discard_all_references
end
