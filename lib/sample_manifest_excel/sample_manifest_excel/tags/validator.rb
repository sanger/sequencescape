module SampleManifestExcel
  module Tags
    # TODO: A bit of abstraction to make this suitable for other users.
    module Validator
      module Uniqueness
        extend ActiveSupport::Concern

        included do
          validate :check_tags
        end

        def check_tags
          tag_oligo_column = upload.columns.find_by(:name, :tag_oligo)
          tag2_oligo_column = upload.columns.find_by(:name, :tag2_oligo)
          if tag_oligo_column.present? & tag2_oligo_column.present?
            combinations = upload.rows.data_at(tag_oligo_column.number).zip(upload.rows.data_at(tag2_oligo_column.number))
            errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
          end
        end
      end

      module Formatting
        extend ActiveSupport::Concern

        included do
          validate :check_formatting
        end

        def check_formatting
          if value.present?
            unless value.match?(/\A[acgtACGT]+\z/)
              errors.add(:tag, 'must be a combination of A,C,G and T')
            end
          end
        end
      end
    end
  end
end
