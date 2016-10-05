module SampleManifestExcel
  module SpecialisedFields

    module TagGroupValidation
      include HashAttributes

      extend ActiveSupport::Concern

      included do
        set_attributes :tag_group_cache, :tag_index
        validate :check_tag_group, :check_tag_index, if: :cache_and_value_present?
      end

    private

      def tag_group
        @tag_group ||= if cache_and_value_present?
          tag_group_cache.find(value)
        end
      end

      def check_tag_group
        errors.add(:value, "Tag Group does not exist.") unless tag_group.present?
      end

      def check_tag_index
        if tag_index.present?
          unless tag_group.tags.detect {|tag| tag.map_id == tag_index.to_i}.present?
            errors.add(:tag_index, "Tag Index is not within Tag Group.")
          end
        end
      end

      def cache_and_value_present?
        value_present? && tag_group_cache.present?
      end

    end

    # We need to load base first as all other specialised fields inherit from it
    require_relative "specialised_fields/base"

    Dir[File.join(File.dirname(__FILE__),"specialised_fields","*.rb")].each do |file|
      unless File.basename(file,".rb") == "base"
        require file
      end
    end


  end
end