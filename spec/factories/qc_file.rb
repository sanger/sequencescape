# frozen_string_literal: true

FactoryBot.define do
  factory :qc_file, class: 'QcFile' do
    transient do
      filename { 'qc_file.csv' }
      contents { "A1,A2,A3\n1,2,3\n4,5,6\n" }
      tempfile do
        Tempfile.new.tap do |file|
          file.write(contents)
          file.rewind # Be polite, ensure the file pointer is at the beginning
        end
      end
    end

    uploaded_data { { tempfile:, filename: } }

    # Relationships
    asset factory: %i[labware]
  end
end
