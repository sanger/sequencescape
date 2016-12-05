module Accession
  class TagList

    include Enumerable

    attr_reader :tags

    delegate :keys, :values, to: :tags

    def initialize(tags = {})
      create_tags(tags)
      yield self if block_given?
    end

    def each(&block)
      tags.each(&block)
    end

    def required_for(service)
      tags.values.select { |tag| tag.required_for?(service)}
    end

    def find(key)
      tags[key.to_s]
    end

    def by_group
      tags.values.inject({}) do |result, tag|
        tag.groups.each do |group|
          result[group] ||= []
          result[group] << tag
        end
        result
      end
    end

    def add(tag)
      tags[tag.name] = tag
    end

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
      self.required_for(service).count == standard_tags.required_for(service).count
    end

  private

    def create_tags(tags)
      @tags = {}.tap do |_tags|
        tags.each do |k, tag|
          _tags[k] = Accession::Tag.new(tag.merge(name: k))
        end
      end
    end
  end
end