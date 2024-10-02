# frozen_string_literal: true

namespace :support do
  # This task needs to be executed before creating the unique-together index on
  # the ancestor_id and descendant_id columns of the asset_links table. The
  # index creation will be done using a migration. If there are already
  # duplicate records, the migration will fail. This task fixes that by finding
  # all the duplicate asset links and removes all but the most recently created
  # one. The task requires an argument to save the removed duplicates to a file
  # for auditing purposes.
  desc 'Remove duplicate asset links'
  task remove_duplicate_asset_links: :environment do |_t, args|
    csv_file_path = args.extras.first # Positional argument.
    if csv_file_path.nil?
      puts "Usage: rake 'support:remove_duplicate_asset_links[csv_file_path]'"
      exit 1
    end

    duplicates_removed = 0

    ActiveRecord::Base.transaction do
      CSV.open(Rails.root.join(csv_file_path), 'w') do |csv|
        csv << AssetLink.column_names # Write the headers
        AssetLink
          .group(:ancestor_id, :descendant_id)
          .having('count(*) > 1')
          .each do |link|
            duplicates =
              AssetLink
                .where(ancestor_id: link.ancestor_id, descendant_id: link.descendant_id)
                .order(created_at: :desc)
                .offset(1) # Except the most recent one.
            duplicates.each { |duplicate| csv << duplicate.attributes.values }
            duplicates.delete_all
            duplicates_removed += duplicates.size
          end
      end
    end

    Rails.logger.info("Removed #{duplicates_removed} duplicate asset links.")
    puts "Deleted records have been exported to #{csv_file_path}"
  end
end
