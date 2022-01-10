# frozen_string_literal: true

namespace :application do
  # In Sanger PSD we have the ansible deployment project configured to run:
  # `rails db:migrate`` --> `rake application:post_deploy`
  #
  # Record loader is configured here to run *before* limber:setup,
  # so we can gradually get rid of limber:setup by migrating things into record loader.
  # This allows limber:setup to be dependent on record loader, which makes things easier to migrate.
  task post_deploy: %w[record_loader:all limber:setup]
end
