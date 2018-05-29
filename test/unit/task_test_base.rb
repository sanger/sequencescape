# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class TaskTestBase < ActiveSupport::TestCase
  class << self
    def expected_partial(name)
      context '#partial' do
        should "return #{name}" do
          assert_equal @task.partial, name
        end
      end
    end
  end

  def task_instance_for(task_module, &block)
    object = Object.new
    object.class_eval { include task_module }
    object.class_eval(&block)
    object
  end
end
