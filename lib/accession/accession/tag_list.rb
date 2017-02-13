module Accession

  #Tags details are stored in config/accession/tags.yml
  #Standard TagList is created on initialisation from this yaml file and can be reached through Accession.configuration.tags
  #TagList that is specific to a particular sample can be created using #extract method (where 'record' is a Sequencescape Sample::Metadata object)
  #Tags contain information about a sample, that should be provided to an external service to accession the sample
  #Tags are used to validate a sample and to create a correct xml file for accessioning request.

  class TagList
    include Enumerable
    include Comparable

    attr_reader :tags, :missing
    attr_accessor :groups

    delegate :keys, :values, to: :tags

    def initialize(tags = {})
      @tags = {}
      add_tags(tags.with_indifferent_access)
      @groups = by_group.keys
      yield self if block_given?
    end

    def each(&block)
      tags.each(&block)
    end

    def required_for(service)
      tags.select { |k, tag| tag.required_for?(service) }
    end

    def find(key)
      tags[key.to_s]
    end

    def by_group
      {}.tap do |result|
        tags.values.each do |tag|
          tag.groups.each do |group|
            result[group] ||= TagList.new
            result[group] << tag
          end
        end
        groups.each {|group| result[group] ||= {}} if groups.present?
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

    def meets_service_requirements?(service, standard_tags)
      @missing = standard_tags.required_for(service).keys - self.required_for(service).keys
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
