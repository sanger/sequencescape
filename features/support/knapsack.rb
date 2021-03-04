# frozen_string_literal: true

require 'knapsack_pro'
# https://knapsackpro.com/faq/question/how-to-use-simplecov-in-queue-mode
KnapsackPro::Hooks::Queue.before_queue do |queue_id|
  command = "cucumber_ci_node_#{KnapsackPro::Config::Env.ci_node_index}_#{queue_id}"
  SimpleCov.command_name(command)
end

KnapsackPro::Adapters::CucumberAdapter.bind
# So the instructions above are actually insufficient, as Knpasack Pro spins up
# a seperate cucumber process for each subset of the queue. This results in Simplecov
# clobbering the coverage. Before queue runs only the once, whereas this will run
# on each invokation
SimpleCov.command_name("#{SimpleCov.command_name}_#{ENV['KNAPSACK_PRO_SUBSET_QUEUE_ID']}")
