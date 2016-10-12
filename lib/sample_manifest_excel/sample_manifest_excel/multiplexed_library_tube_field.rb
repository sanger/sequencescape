module SampleManifestExcel
  module MultiplexedLibraryTubeField

    class Base
      include SpecialisedField
    end

    module ValueToInteger
      def value
        @value.to_i if @value.present?
      end
    end

    module TagGroupValidation

      extend ActiveSupport::Concern

      included do
        attr_reader :tag_group_cache, :tag_index
        validate :check_tag_group, :check_tag_index, if: :cache_and_value_present?
      end

      def update(attributes = {})
        
        if attributes[:tag_group_cache].present?
          @tag_group_cache = attributes[:tag_group_cache]
        end

        if attributes[tag_index_key].present?
          @tag_index = attributes[tag_index_key]
        end

        super
      end

    private

      def tag_index_key
        @tag_index_key ||= "#{type.to_s.split("_").first}_index".to_sym
      end

      def tag_group
        @tag_group ||= if cache_and_value_present?
          tag_group_cache.find(value)
        end
      end

      def check_tag_group
        errors.add(:value, "Tag Group does not exist.") unless tag_group.present?
      end

      def check_tag_index
        if tag_index.present? && tag_group.present?
          unless tag_group.tags.detect { |tag| tag.map_id == tag_index.value }.present?
            errors.add(:tag_index, "Tag Index is not within Tag Group.")
          end
        end
      end

      def cache_and_value_present?
        value_present? && tag_group_cache.present?
      end

    end

    Dir[File.join(File.dirname(__FILE__),"multiplexed_library_tube_field","*.rb")].each  { |file| require file }

    SpecialisedField.create_field_list(self)
    

  end
end