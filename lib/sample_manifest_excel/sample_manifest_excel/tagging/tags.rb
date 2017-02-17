module SampleManifestExcel
  module Tagging
    class Tags
      include ActiveModel::Model

      attr_reader :aliquot, :tag_oligo, :tag2_oligo, :tag_group
      validates_presence_of :aliquot, :tag_oligo, :tag2_oligo

      # I expect row to be valid and respond to sample_id, tag_oligo, tag2_oligo
      def initialize(row)
        @aliquot = find_aliquot_by(sanger_sample_id: row.sample_id)
        @tag_oligo = row.tag_oligo
        @tag2_oligo = row.tag2_oligo
        @tag_group = SampleManifestExcel.configuration.tag_group
      end

      def find_aliquot_by(sanger_sample_id:)
        sample = Sample.find_by(sanger_sample_id: sanger_sample_id)
        Aliquot.find_by(sample_id: sample.id) if sample.present?
      end

      def find_tag_by(oligo:)
        tag_group.tags.find_or_create_by(oligo: oligo) do |tag|
          tag.map_id = tag_group.tags.count + 1
        end
      end

      # I need to discuss how to handle oligo = -1
      def update
        aliquot.tag = find_tag_by(oligo: tag_oligo)
        aliquot.tag2 = find_tag_by(oligo: tag2_oligo) unless tag2_oligo == '-1'
        aliquot.save
      end
    end
  end
end
