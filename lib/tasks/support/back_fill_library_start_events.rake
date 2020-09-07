# frozen_string_literal: true

namespace :support do
  desc 'Back fill missing library start data https://github.com/sanger/unified_warehouse/issues/119'
  task :back_fill_library_start_events, [:batch_id, :library_type_name] => [:environment] do
    require_relative 'back_fill_library_events'
    # Indicates the date after which to check for existing events. This process is slow
    # so we only check when we have a possibility of events.
    # We don't use the RELEASE_NAME just in case the running of the rake task gets
    # delayed beyond a release
    DEPLOY_DATE = DateTime.parse(ENV.fetch('DEPLOY_DATE', 'Fri, 04 Sep 2020 09:49:27 +0100')).freeze
    BackFillLibraryEvents.new(DEPLOY_DATE).run
  end
end
