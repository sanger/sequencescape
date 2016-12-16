module Accession
  class TagList

    include Enumerable
    include Comparable

    attr_reader :tags, :missing

    delegate :keys, :values, to: :tags

    def initialize(tags = {})
      @tags = {}
      add_tags(tags.with_indifferent_access)
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
      tags.values.inject({}) do |result, tag|
        tag.groups.each do |group|
          result[group] ||= TagList.new
          result[group] << tag
        end
        result
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
        end)
      end
    end
  end
end