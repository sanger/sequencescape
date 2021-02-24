# frozen_string_literal: true

require "test_prof/before_all"

module TestProf
  module BeforeAll
    # Add before_all hook to Minitest: wrap all examples into a transaction and
    # store instance variables
    module Minitest # :nodoc: all
      class Executor
        attr_reader :active, :block, :captured_ivars, :teardown_block, :current_test_object,
          :setup_fixtures

        alias active? active
        alias setup_fixtures? setup_fixtures

        def initialize(setup_fixtures: false, &block)
          @setup_fixtures = setup_fixtures
          @block = block
          @captured_ivars = []
        end

        def teardown(&block)
          @teardown_block = block
        end

        def activate!(test_object)
          @current_test_object = test_object

          return restore_ivars(test_object) if active?
          @active = true
          BeforeAll.setup_fixtures(test_object) if setup_fixtures?
          BeforeAll.begin_transaction do
            capture!(test_object)
          end
        end

        def deactivate!
          @active = false

          current_test_object&.instance_eval(&teardown_block) if teardown_block

          @current_test_object = nil
          BeforeAll.rollback_transaction
        end

        def capture!(test_object)
          return unless block

          before_ivars = test_object.instance_variables

          test_object.instance_eval(&block)

          (test_object.instance_variables - before_ivars).each do |ivar|
            captured_ivars << [ivar, test_object.instance_variable_get(ivar)]
          end
        end

        def restore_ivars(test_object)
          captured_ivars.each do |(ivar, val)|
            test_object.instance_variable_set(
              ivar,
              val
            )
          end
        end
      end

      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      module ClassMethods
        attr_accessor :before_all_executor

        def before_all(setup_fixtures: BeforeAll.config.setup_fixtures, &block)
          self.before_all_executor = Executor.new(setup_fixtures: setup_fixtures, &block)

          prepend(Module.new do
            def before_setup
              self.class.before_all_executor.activate!(self)
              super
            end
          end)

          singleton_class.prepend(Module.new do
            def run(*)
              super
            ensure
              before_all_executor&.deactivate!
            end
          end)
        end

        def after_all(&block)
          self.before_all_executor ||= Executor.new
          before_all_executor.teardown(&block)
        end
      end
    end
  end
end
