# frozen_string_literal: true

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

  def task_instance_for(task_module, &)
    object = Object.new
    object.class_eval { include task_module }
    object.class_eval(&)
    object
  end
end
