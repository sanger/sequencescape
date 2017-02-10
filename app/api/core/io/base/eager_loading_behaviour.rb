# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Core::Io::Base::EagerLoadingBehaviour
  def set_eager_loading
    singleton_class.class_eval do
      define_method(:eager_loading_for) do |loaded_class|
        yield(super(loaded_class))
      end
    end
  end

  def eager_loading_for(model)
    model or raise StandardError, 'nil model does not make sense here at all!'
  end
end
