# frozen_string_literal: true

# # One-time task run to deprecate the LRC Bank Input tube purpose.
# # For reference: Y26-075

namespace :LRC_BANK_INPUT do
  desc 'Deprecate LRC Bank Input tube purpose'
  task deprecate_lrc_bank_input_purpose: :environment do
    lrc_bank_input_purpose = Tube::Purpose.find_by(name: 'LRC Bank Input')

    unless lrc_bank_input_purpose
      puts "Tube Purpose 'LRC Bank Input' not found. No action taken."
      next
    end

    lrc_bank_input_purpose.update!(deprecated: true, deprecated_at: DateTime.now)

    puts 'Done: LRC Bank Input tube purpose is been deprecated.'
  end
end
