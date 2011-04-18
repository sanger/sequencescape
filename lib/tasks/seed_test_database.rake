# This ensures that the test database is seeded with the correct data before any tests
# are run.  The great thing about this is that it happens before *all* tests and features,
# or just before the specific one requested.
namespace :db do
  namespace :test do
    task :load => :environment do
      Rake::Task["db:seed"].invoke
    end
  end
end

