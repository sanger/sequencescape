# frozen_string_literal: true

# Temporary task to prevent accidental addition of in-progress schema changes
Rake::Task['db:schema:dump'].enhance ['asset_refactor:guard_schema_dump']

namespace :asset_refactor do
  task :guard_schema_dump do
    AssetRefactor.when_refactored do
      puts Rainbow(<<~HEREDOC
        Schema dump is blocked due to presence of Labware table.
        This is to prevent experimental schema changes from being commited.
        See app/models/asset_refactor.rb for more information.
        This file can be deleted once the refactoring process is complete.
      HEREDOC
                  ).red
      exit
    end
  end

  desc 'Runs the experimental asset refactor migrations'
  task migrate: :environment do
    Dir.glob(Rails.root.join('db', 'migrate_asset_refactor', '*.rb')).sort.each do |file|
      # Extract the version and migration name from the filename
      match_data = %r{/([\d]+)_(\w+).rb}.match(file)
      version = match_data[1]
      migration = match_data[2]
      # Skip the migration if it has already run
      next if ActiveRecord::SchemaMigration.find_by(version: version.to_s)

      # Load the file
      require file
      # Run it
      migration.camelcase.constantize.migrate(:up)
      # Record that we've run it
      ActiveRecord::SchemaMigration.create!(version: version.to_s)
    end
  end

  desc 'Rollback the experimental asset refactor migrations'
  task rollback: :environment do
    Dir.glob(Rails.root.join('db', 'migrate_asset_refactor', '*.rb')).sort.reverse_each do |file|
      # Extract the version and migration name from the filename
      match_data = %r{/([\d]+)_(\w+).rb}.match(file)
      version = match_data[1]
      migration = match_data[2]
      # Skip the migration if it has not been run
      next unless ActiveRecord::SchemaMigration.find_by(version: version.to_s)

      # Load the file
      require file
      # Reverse it it
      migration.camelcase.constantize.migrate(:down)
      # Record that we've rolled back
      ActiveRecord::SchemaMigration.find_by(version: version.to_s).destroy
    end
  end

  desc 'Copies the migrations to the migrate folder with appropriate timestamps'
  task finalize: :environment do
    base_time = Time.now.utc
    Dir.glob(Rails.root.join('db', 'migrate_asset_refactor', '*.rb')).sort.each_with_index do |file, index|
      match_data = %r{/([\d]+)_(\w+).rb}.match(file)
      # Ensure our timestamps maintain the original order.
      version = (base_time + index).strftime('%Y%m%d%H%M%S').to_i
      migration = match_data[2]
      FileUtils.cp(file, Rails.root.join('db', 'migrate', "#{version}_#{migration}.rb"))
    end
    puts 'Migrations copied. It is now safe to delete db/migrate_asset_refactor'
  end
end
