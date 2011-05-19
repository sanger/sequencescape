module Core::Io::Base::JsonFormattingBehaviour
  def self.extended(base)
    base.class_eval do
      extend ::Core::Io::Base::JsonFormattingBehaviour::Input
      extend ::Core::Io::Base::JsonFormattingBehaviour::Output
      extend ::Core::Io::Base::JsonFormattingBehaviour::Debug unless Rails.env == 'production'

      class_inheritable_reader :attribute_to_json_field
      write_inheritable_attribute(:attribute_to_json_field, {})
      delegate :json_field_for, :to => 'self.class'
    end
  end

  module Debug
    def as_json(options = nil, &block)
      return super if options[:nested]
      benchmark("I/O #{self.name}") { super }
    end
  end

  def as_json(options = nil, &block)
    options        ||= {}
    object           = options.delete(:object)
    uuids_to_ids     = options[:uuids_to_ids] || { }
    object_content   = object_json(object, uuids_to_ids, options)

    options[:nested] ? object_content : { self.json_root => object_content, :uuids_to_ids => uuids_to_ids }
  end

  #--
  # Very root level does absolutely nothing useful!
  #++
  def object_json(object, uuids_to_ids, options)
    {}
  end
  private :object_json

  def post_process(json)
    # Does nothing, intentionally
  end

  def json_field_for(attribute)
    attribute_to_json_field[attribute.to_s] || attribute.to_s
  end

  def set_json_root(name)
    @json_root = name.to_sym
  end

  def json_root
    @json_root or raise StandardError, "JSON root is not set for #{self.name}"
  end

  def api_root
    self.json_root.to_s.pluralize
  end

  def define_attribute_and_json_mapping(mapping)
    parse_mapping_rules(mapping) do |attribute_to_json, json_to_attribute|
      self.attribute_to_json_field.merge!(attribute_to_json)
      generate_object_to_json_mapping(attribute_to_json)
      generate_json_to_object_mapping(json_to_attribute)
    end
  end

  VALID_LINE_REGEXP = /^\s*((?:[a-z_][\w_]*\.)*[a-z_][\w_]*[?!]?)\s*(<=|<=>|=>)\s*((?:[a-z_][\w_]*\.)*[a-z_][\w_]*)\s*$/

  def parse_mapping_rules(mapping, &block)
    attribute_to_json, json_to_attribute = {}, {}
    StringIO.new(mapping).each_line do |line|
      next if line.blank? or line =~ /^\s*#/
      match = VALID_LINE_REGEXP.match(line) or raise StandardError, "Invalid line: #{line.inspect}"
      attribute_to_json[match[1]] = match[3] if (match[2] =~ /<?=>/) 
      json_to_attribute[match[3]] = (match[2] =~ /<=>?/) ? match[1] : nil
    end
    yield(attribute_to_json, json_to_attribute)
  end
  private :parse_mapping_rules
end
