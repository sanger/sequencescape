# frozen_string_literal: true
#
# The initial implementation for collecting under-represented wells within a batch exhibited several inconsistencies.
# In certain cases, under-represented wells were not collected because the implementation failed to correctly match
# aliquots in the pool with aliquots on the marked plate, resulting in no data being transmitted to the MLWH.
# In other instances, only a partial set of wells was collected, as only a limited number of aliquots were
# successfully matched, leading to incomplete data being forwarded.
# Additionally, duplicate records of under-represented wells were identified in some scenarios,
# where samples were pooled from two different plates and the same well position was marked in both.
# These duplicates resulted in messages being dead-lettered during insertion into the MLWH.
# This issue has since been corrected. However, a backfill is required to ensure
# that all previously omitted data is correctly propagated to the MLWH.
#
#   Related research story: Y26-156.

namespace :under_rep_well_comments do
  desc 'broadcast missing under represented wells to the MLWH'
  task broadcast: :environment do
    batch_ids = [107452, 107331, 107510, 107514, 107822, 107770, 108006, 108086, 107879, 107940, 108306]
    batch_ids.each do |batch_id|
      batch = Batch.find(batch_id)
      if batch
        batch.messengers.select(root: 'comment').first.resend
        puts "Under-represented wells for batch #{batch_id} have been broadcast to the MLWH"
      else
        puts "batch with id #{batch_id} not found"
      end
    end
  end
end
