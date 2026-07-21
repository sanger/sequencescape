# frozen_string_literal: true
# This is a rake task to rebroadcast studies to backfill data release prevention reason in MLWH.(story Y26-200)
namespace :studies do
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
        study.rebroadcast
      end
    end

    puts 'Done.'
  end
end
