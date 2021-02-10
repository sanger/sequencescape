# frozen_string_literal: true

require 'knapsack_pro'
# https://knapsackpro.com/faq/question/how-to-use-simplecov-in-queue-mode
KnapsackPro::Hooks::Queue.before_queue do |queue_id|
  run_id = "#{queue_id}_#{Time.now.to_i}"
  SimpleCov.command_name("cucumber_ci_node_#{KnapsackPro::Config::Env.ci_node_index}_#{run_id}")
end
KnapsackPro::Adapters::CucumberAdapter.bind
