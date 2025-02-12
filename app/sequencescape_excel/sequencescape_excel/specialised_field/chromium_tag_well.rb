# frozen_string_literal: true
module SequencescapeExcel
  module SpecialisedField
    ##
    # ChromiumTagWell
    #
    # This class represents a tag well for Chromium.
    # It includes common functionality from ChromiumTagWellCommon.
    class ChromiumTagWell
      include ChromiumTagWellCommon

      ##
      # Returns the class of the associated tag group.
      #
      # This method returns the class that represents the associated tag group
      # for this tag well.
      #
      # @return [Class] The class of the associated tag group.
      def self.tag_group_class
        SequencescapeExcel::SpecialisedField::ChromiumTagGroup
      end
    end
  end
end
