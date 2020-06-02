# frozen_string_literal: true

namespace :application do
  task deploy: ['limber:setup']
  # Placeholder task for RecordLoader behaviour
  task :post_deploy
end
