# frozen_string_literal: true

# Factories related to transfers
FactoryBot.define do
  factory(:transfer_between_plates, class: 'Transfer::BetweenPlates') do
    user
    source factory: %i[transfer_plate]
    destination factory: %i[plate_with_empty_wells]
    transfers { { 'A1' => 'A1', 'B1' => 'B1' } }

    factory(:full_transfer_between_plates) do
      source factory: %i[full_plate]
      destination factory: %i[full_plate]
      transfers { ('A'..'H').map { |r| (1..12).map { |c| "#{r}#{c}" } }.flatten.to_h { |w| [w, w] } }
    end
  end

  factory(:transfer_from_plate_to_tube, class: 'Transfer::FromPlateToTube') do
    user
    source { |target| target.association(:transfer_plate) }
    destination { |target| target.association(:library_tube) }

    factory(:transfer_from_plate_to_tube_with_transfers) { transfers { %w[A1 B1] } }
  end

  # Factory for Transfer::FromPlateToTubeBySubmission.
  # Creates a source plate with one well that has a library_completion request (for_multiplexing: true)
  # pointing to an MX library tube, plus a stock Well::Link so plate.stock_wells returns the well.
  # Call build_library_completion_for_well and link_stock_well helpers in specs to customise further.
  factory(:transfer_from_plate_to_tube_by_submission, class: 'Transfer::FromPlateToTubeBySubmission') do
    user
    source factory: %i[transfer_plate], well_count: 1
  end

  factory(:transfer_template) do
    sequence(:name) { |n| "Transfer Template #{n}" }
    transfer_class_name { 'Transfer::BetweenPlates' }
    transfers { { 'A1' => 'A1', 'B1' => 'B1' } }

    factory(:pooling_transfer_template) do
      transfer_class_name { 'Transfer::BetweenPlatesBySubmission' }
      transfers { nil } # BySubmission transfer types do not define the transfers in the template.
    end

    factory(:multiplex_transfer_template) do
      transfer_class_name { 'Transfer::FromPlateToTubeByMultiplex' }
      transfers { nil } # ByMultiplex transfer types do not define the transfers in the template.
    end

    factory :between_tubes_transfer_template do
      transfer_class_name { 'Transfer::BetweenTubesBySubmission' }
      transfers { nil } # BySubmission transfer types do not define the transfers in the template.
    end
  end
end
