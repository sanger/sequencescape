#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
require "test_helper"

class TaskTest < ActiveSupport::TestCase
  context "A Task" do
    should belong_to :workflow
    should have_many :families
    should have_many :descriptors
  end

  context "A SetDescriptorsTask" do
    setup do
      @task = SetDescriptorsTask.new
    end

    should "store a descriptor" do
      @task.set_descriptor_value("name", "value")
      assert_equal 1, @task.descriptors.size
    end

    should "return nil to a unknown descriptor" do
      assert_nil @task.get_descriptor_value("undefined")
    end

    context "with a descriptor" do
      setup do
        @task.set_descriptor_value("name", "value")
      end

      should "get is value" do
        assert_equal "value", @task.get_descriptor_value("name")
      end

      should "overwrite existing value" do
        @task.set_descriptor_value "name", "new_value"
        assert_equal 1, @task.descriptors.size
        assert_equal "new_value", @task.get_descriptor_value("name")
      end

      should "save them" do
        descriptor_count = Descriptor.count
        @task.save
        assert_equal descriptor_count+1, Descriptor.count
      end

      should "get descriptor with a default value" do
        assert_equal"my_default_value", @task.get_descriptor_value("new_name", "my_default_value")
      end
    end
  end

  context "A Task subclass" do
    setup do
      class MyTask  < Task
      end
    end
    teardown do
      TaskTest.send(:remove_const, :MyTask)
      #      self.send(:remove_const, :MyTask)
    end
    should "define subclass_attribute attribute" do
      class MyTask
        set_subclass_attribute :att
      end
    end
    context "with subclass_attributes" do
      setup do
        class MyTask
          set_subclass_attribute :att
        end
        @task = MyTask.new
      end


      should "access define access  method" do
        assert @task.respond_to?(:att)
      end
      should "access define access write method" do
        assert @task.respond_to?(:att=)
      end
      should "not accept the same subclass_attribute definition twice" do
        assert_raises ArgumentError do
          class MyTask
            set_subclass_attribute :att
          end
        end
      end

      should "set subclass_attributes via attribute" do
        @task.att= "value"
        assert_equal "value", @task.get_subclass_attribute_value(:att)
      end

      should "get subclass_attributes via attribute" do
        @task.att= "value"
        assert_equal "value", @task.att
      end

      should "return null as ultimate default value" do
        assert_nil @task.att
      end

      context "and default value" do
        setup do
          class MyTask
            set_subclass_attribute :att_with_default, :default => "default_value"
          end
        end
        should "use default value if subclass_attribute not set" do
          assert_equal "default_value", @task.att_with_default
        end
      end

      context "with a saved value" do
        setup do
          @initial_value = "initial_value"
          @task.att= @initial_value
          @task.save
        end

        should "have this value in the database" do
          a = SubclassAttribute.find_by_value!(@initial_value)
          assert a
          assert_equal @task.id, a.attributable_id # sti doesn't work with class defined on the flight, so a.attributable doesn't work
        end

        should "update value in the database" do
          new_value = "the new value"
          @task.att = new_value
          @task.save!

          a = SubclassAttribute.find_by_value!(new_value)
          assert a
          assert_equal @task.id, a.attributable_id
        end
      end
    end
  end

end
