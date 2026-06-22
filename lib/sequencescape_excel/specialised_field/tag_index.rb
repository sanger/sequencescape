# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # TagIndex
    class TagIndex
      include Base
      include ValueToInteger

      attr_accessor :sf_tag_group

      validate :check_tag_index

      def update(_attributes = {})
        return unless valid?

        aliquots.each { |aliquot| aliquot.tag = tag } if tag.present? && tag.oligo.present?
      end

      def link(other_fields)
        self.sf_tag_group = other_fields[SequencescapeExcel::SpecialisedField::TagGroup]
      end

      private

      def tag
        return @tag if defined?(@tag)

        @tag = ::Tag
          .where.not(tag_group_id: nil)
          .where.not(map_id: nil)
          .find_by(tag_group_id: sf_tag_group.tag_group_id, map_id: value)
      end

      # check the index exists within the group exists here, check the group/index combination later
      def check_tag_index
        if sf_tag_group.nil?
          errors.add(:base, "no corresponding tag group supplied for tag index #{value}")
        else
          return if tag.present?

          errors.add(:base, "could not find a tag with tag_group_id #{sf_tag_group.tag_group_id} and index #{value}.")
        end
      end
    end
  end
end
