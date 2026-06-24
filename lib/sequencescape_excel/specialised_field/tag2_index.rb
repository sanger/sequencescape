# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # TagIndex
    class Tag2Index
      include Base
      include ValueToInteger

      attr_accessor :sf_tag2_group

      validate :check_tag2_index

      def update(_attributes = {})
        return unless valid?

        aliquots.each { |aliquot| aliquot.tag2 = tag } if tag.present? && tag.oligo.present?
      end

      def link(other_fields)
        self.sf_tag2_group = other_fields[SequencescapeExcel::SpecialisedField::Tag2Group]
      end

      private

      def tag
        return @tag if defined?(@tag)

        @tag = ::Tag
          .where.not(tag_group_id: nil)
          .where.not(map_id: nil)
          .find_by(tag_group_id: sf_tag2_group.tag2_group_id, map_id: value)
      end

      # check the index exists within the group exists here, check the group/index combination later
      def check_tag2_index
        return if value.blank?

        if sf_tag2_group.nil?
          errors.add(:base, "no corresponding tag2 group supplied for tag2 index #{value}")
        else
          return if tag.present?

          errors.add(
            :base,
            "could not find a tag2 with tag_group_id #{sf_tag2_group.tag2_group_id} and tag index #{value}."
          )
        end
      end
    end
  end
end
