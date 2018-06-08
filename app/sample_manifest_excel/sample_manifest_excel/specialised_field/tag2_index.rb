# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # TagIndex
    class Tag2Index
      include Base
      include ValueToInteger

      attr_accessor :sf_tag2_group

      validate :check_tag2_index

      def update(attributes = {})
        return unless valid?
        tag2 = ::Tag.find_by(tag_group_id: sf_tag2_group.tag2_group_id, map_id: value) if sf_tag2_group.present? && value.present?
        attributes[:aliquot].tag2 = tag2 if tag2.present? && tag2.oligo.present?
      end

      private

      # check the index exists within the group exists here, check the group/index combination later
      def check_tag2_index
        if sf_tag2_group.nil?
          errors.add(:base, "no corresponding tag2 group supplied for tag2 index #{value}")
        else
          return if ::Tag.find_by(tag_group_id: sf_tag2_group.tag2_group_id, map_id: value).present?
          errors.add(:base, "could not find a tag2 with tag_group_id #{sf_tag2_group.tag2_group_id} and tag index #{value}.")
        end
      end
    end
  end
end
