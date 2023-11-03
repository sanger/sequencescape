# frozen_string_literal: true

namespace :support do
  desc 'Update the library types of all the lanes of the given batch https://github.com/sanger/sequencescape/blob/develop/lib/tasks/README.md#update-library-type-for-given-batch'
  task :update_library_types, %i[batch_id library_type_name] => [:environment] do |_task, args|
    puts('*' * 80)
    puts('TASK STARTING')
    puts('*' * 80)
    start = Time.zone.now

    batch_id = args.batch_id
    batch_id = Integer(batch_id)

    library_type_name = args.library_type_name

    puts('Confirming library type')
    new_library_type =
      LibraryType.find_by(name: library_type_name) || raise("Unable to find library type #{library_type_name}")

    # Get the lanes for this batch
    puts('Getting lanes for this batch')
    lanes = Batch.find(batch_id).batch_requests.map(&:request).map(&:target_asset).map(&:labware)

    raise('No lanes found for this batch') if lanes.count.zero?

    record_count = 0
    ActiveRecord::Base.transaction do
      puts('Updating records')
      lanes.each do |lane|
        lane.aliquots.each do |aliquot|
          Aliquot
            .where(library_id: aliquot.library_id)
            .find_each do |ali|
              ali.library_type = new_library_type.name
              ali.save!
              record_count += 1
            end
        end
      end
    end

    puts('Touching the batch to send messages to update the MLWH')
    Batch.find(batch_id).touch # rubocop:disable Rails/SkipsModelValidations

    done = Time.zone.now
    print_summary(batch_id, lanes, record_count, done - start)
  rescue ArgumentError => e
    puts('*' * 80)
    puts('ERROR')
    puts('*' * 80)
    puts(e)
    abort("#{batch_id} needs to be an integer")
  rescue StandardError => e
    puts('*' * 80)
    puts('ERROR')
    puts('*' * 80)
    puts(e)
    puts(e.backtrace)
  end

  def print_summary(batch_id, lanes, record_count, elapsed) # rubocop:todo Metrics/AbcSize
    puts('*' * 80)
    puts('TASK COMPLETE')
    puts('*' * 80)
    puts("Batch ID: #{batch_id}")
    puts("Number of lanes: #{lanes.count}")
    puts("Lane IDs: #{lanes.map(&:id)}")
    puts("Lane class name: #{lanes.first.class.name}")
    puts("Total records (aliquots) updated: #{record_count}")
    puts("Elapsed time: #{elapsed.round(1)}s")
  end
end
