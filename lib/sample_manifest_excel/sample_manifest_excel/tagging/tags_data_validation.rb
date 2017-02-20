module SampleManifestExcel
  module Tagging
    module TagsDataValidation
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Model

        attr_accessor :tags_oligos, :tags2_oligos

        validates_presence_of :tags_oligos, :tags2_oligos
        validate :tag_combination_is_unique, if: 'tags_oligos.present?'

        def tag_combination_is_unique
          combinations = tags_oligos.zip(tags2_oligos)
          errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
        end
      end
    end
  end
end
