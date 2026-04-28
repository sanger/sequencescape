# frozen_string_literal: true
# One-time task to repurpose LBSN-96 Lysate plates without a parent
# to LBSN-96 Lysate Input.
# for reference Y26-067

namespace :LBSN_96_Lysate do
  desc 'Repurpose LBSN-96 Lysate plates with no parent to LBSN-96 Lysate Input'
  task repurpose_lbsn_lysate_plates_without_parents: :environment do
    lbsn_lysate_purpose = PlatePurpose.find_by(name: 'LBSN-96 Lysate')
    raise "PlatePurpose 'LBSN-96 Lysate' not found" unless lbsn_lysate_purpose

    lbsn_lysate_input_purpose = PlatePurpose.find_by(name: 'LBSN-96 Lysate Input')
    raise "PlatePurpose 'LBSN-96 Lysate Input' not found" unless lbsn_lysate_input_purpose

    lbsn_lysate_plates = Plate.where(plate_purpose_id: lbsn_lysate_purpose.id)

    plates_without_parents = lbsn_lysate_plates.select { |plate| plate.parents.empty? }

    puts "Found #{plates_without_parents.size} plates to repurpose"

    plates_without_parents.each do |plate|
      plate.update!(plate_purpose_id: lbsn_lysate_input_purpose.id)
    end

    puts "Done: #{plates_without_parents.size} plates repurposed to 'LBSN-96 Lysate Input'"
  end
end
