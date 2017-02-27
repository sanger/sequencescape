module SampleManifestExcel
  module Tagging
    class Tags
      include ActiveModel::Model

      attr_accessor :sample_id, :aliquot, :tag_oligo, :tag2_oligo, :tag_group
      validates_presence_of :aliquot, :tag_oligo, :tag2_oligo

      def initialize(attributes = {})
        super
        @aliquot = find_aliquot_by(sanger_sample_id: sample_id)
      end

      def update
        aliquot.tag = find_tag_by(oligo: tag_oligo)
        aliquot.tag2 = find_tag_by(oligo: tag2_oligo)
        aliquot.save
      end

      def find_aliquot_by(sanger_sample_id:)
        sample = Sample.find_by(sanger_sample_id: sanger_sample_id)
        sample.aliquots.first if sample.present?
      end

      def find_tag_by(oligo:)
        if oligo.present?
          tag_group.tags.find_or_create_by(oligo: oligo) do |tag|
            tag.map_id = tag_group.tags.count + 1
          end
        end
      end

      def tag_group
        @tag_group ||= SampleManifestExcel.configuration.tag_group
      end
    end
  end
end
