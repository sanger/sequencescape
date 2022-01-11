# frozen_string_literal: true

namespace :application do
  # In Sanger PSD we have the ansible deployment project configured to run:
  # `rake application:deploy` --> `rails db:migrate`` --> `rake application:post_deploy`

  # Leave this here empty in case it's needed in future
  task :deploy

  # Record loader is configured here to run *before* limber:setup,
  # so we can gradually get rid of limber:setup by migrating things into record loader.
  # This allows limber:setup to be dependent on record loader, which makes things easier to migrate.
  task post_deploy: %w[record_loader:all limber:setup]
end
