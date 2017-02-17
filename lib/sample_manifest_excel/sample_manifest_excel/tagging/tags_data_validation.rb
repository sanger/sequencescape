module SampleManifestExcel
  module Tagging
    module TagsDataValidation
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model

        attr_accessor :tags_oligos, :tags2_oligos

        # assuming that we use current approach - oligo is assigned to '-1' if not provided
        validates_presence_of :tags_oligos, :tags2_oligos

        # we also should validate that 'specialized fields' sample_id and tag_oligo are not empty
        # tag2_oligo should be assigned to -1 if empty
        # at some point we should also check that sample_id exists in our db
        validate :tag_combination_is_unique, if: 'tags_oligos.present?'

        def tag_combination_is_unique
          combinations = tags_oligos.zip(tags2_oligos)
          errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
        end
      end
    end
  end
end
