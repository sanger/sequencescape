# frozen_string_literal: true

FactoryBot.define do
  factory :qc_file, class: 'QcFile' do
    transient do
      filename { 'qc_file.csv' }
      tempfile { Tempfile.new.tap { |file| file.write("A1,A2,A3\n1,2,3\n4,5,6\n") } }
    end

    uploaded_data { { tempfile:, filename: } }

    # Relationships
    asset factory: %i[labware]
  end
end
