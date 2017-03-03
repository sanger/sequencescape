module Accession
  # Tags details are stored in config/accession/tags.yml
  # Standard TagList is created on initialisation from this yaml file and can be reached through Accession.configuration.tags
  # TagList that is specific to a particular sample can be created using #extract method (where 'record' is a Sequencescape Sample::Metadata object)
  # Tags contain information about a sample, that should be provided to an external service to accession the sample
  # Tags are used to validate a sample and to create a correct xml file for accessioning request.

  class TagList
    include Enumerable
    include Comparable

    attr_reader :tags, :missing
    attr_accessor :groups

    delegate :keys, :values, to: :tags

    def initialize(tags = {})
      @tags = {}
      add_tags(tags.with_indifferent_access)
      @groups = self.tags.values.collect(&:groups).flatten.uniq
      yield self if block_given?
    end

    def each(&block)
      tags.each(&block)
    end

    def required_for(service)
      tags.select { |_k, tag| tag.required_for?(service) }
    end

    def find(key)
      tags[key.to_s]
    end

    # create a hash of tags based on the groups which will define how the xml is constructed
    # each key will be the group and each value will be a new TagList to allow tag list methods
    # to be called.
    def by_group
      groups.each_with_object({}) { |v, h| h[v] = TagList.new }.tap do |result|
        tags.values.each do |tag|
          tag.groups.each do |group|
            result[group] << tag
          end
        end
      end
    end

    def labels
      tags.values.collect(&:label)
    end

    def values
      tags.values.collect(&:value)
    end

    def array_express_labels
      tags.values.collect(&:array_express_label)
    end

    def add(tag)
      tags[tag.name] = tag
    end
    alias_method :<<, :add

    # Extract a new TagList based on an Accession::Sample
    # The TagList will consist of a tag for which the sample has attributes
    def extract(record)
      TagList.new do |tag_list|
        tags.keys.each do |key|
          value = record.send(key)
          if value.present?
            tag_list.add(tags[key].dup.add_value(value))
          end
        end
        tag_list.groups = groups
      end
    end

    # Check that the tag list meets the requirements for accessioning for a particular service
    # i.e. check that it has the required tags.
    def meets_service_requirements?(service, standard_tags)
      @missing = standard_tags.required_for(service).keys - required_for(service).keys
      missing.empty?
    end

    def <=>(other)
      return unless other.is_a?(self.class)
      tags <=> other.tags
    end

  private

    def add_tags(tags)
      tags.each do |k, tag|
        add(if tag.instance_of?(Accession::Tag)
              add(tag)
            else
              Accession::Tag.new(tag.merge(name: k))
            end
        )
      end
    end
  end
end
