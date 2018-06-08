# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # TagIndex
    class TagIndex
      include Base
      include ValueToInteger

      attr_accessor :sf_tag_group

      validate :check_tag_index

      def update(attributes = {})
        return unless valid?
        tag = ::Tag.find_by(tag_group_id: sf_tag_group.tag_group_id, map_id: value) if sf_tag_group.present? && value.present?
        attributes[:aliquot].tag = tag if tag.present? && tag.oligo.present?
      end

      private

      # check the index exists within the group exists here, check the group/index combination later
      def check_tag_index
        if sf_tag_group.nil?
          errors.add(:base, "no corresponding tag group supplied for tag index #{value}")
        else
          return if ::Tag.find_by(tag_group_id: sf_tag_group.tag_group_id, map_id: value).present?
          errors.add(:base, "could not find a tag with tag_group_id #{sf_tag_group.tag_group_id} and index #{value}.")
        end
      end
    end
  end
end
