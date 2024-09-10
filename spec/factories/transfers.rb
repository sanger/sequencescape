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
