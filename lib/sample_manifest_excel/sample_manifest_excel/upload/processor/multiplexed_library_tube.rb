module SampleManifestExcel
  module Upload
    module Processor
      class MultiplexedLibraryTube < Base

        validate :check_tags

      private

        def check_tags
          tag_oligo_column = upload.columns.find_by(:name, :tag_oligo)
          tag2_oligo_column = upload.columns.find_by(:name, :tag2_oligo)
          if tag_oligo_column.present? & tag2_oligo_column.present?
            combinations = upload.data.column(tag_oligo_column.number).zip(upload.data.column(tag2_oligo_column.number))
            errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
          end
        end
      end
    end
  end
end