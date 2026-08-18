# frozen_string_literal: true
# This is a rake task to rebroadcast studies to backfill data release prevention reason in MLWH.(story Y26-200)
# To run this task, use the following command, notes DRY_RUN=true is optional,
# if you want to do a dry run without actually rebroadcasting the studies, you can set DRY_RUN=true
# [ DRY_RUN=true ] bundle exec rails support:rebroadcast_with_data_release_prevention_reason

namespace :support do
  desc 'Rebroadcast studies with a data release prevention reason'
  task rebroadcast_with_data_release_prevention_reason: :environment do
    studies = Study
      .joins(:study_metadata)
      .includes(:study_metadata)
      .where.not(study_metadata: { data_release_prevention_reason: nil })

    puts "Found #{studies.count} studies"

    studies.find_each do |study|
      puts "Rebroadcasting Study #{study.id} (#{study.name})"
      puts "  Reason: #{study.study_metadata.data_release_prevention_reason}"

      if ENV['DRY_RUN'] == 'true'
        puts '  (dry run)'
      else
        # calling touch to trigger the rebroadcast of the study to MLWH
        study.touch # rubocop:disable Rails/SkipsModelValidations
      end
    end

    puts 'Done.'
  end
end
