module ::Core::Io::Base::JsonFormattingBehaviour::Output
  def generate_object_to_json_mapping(attribute_to_json)
    code = attribute_to_json.concat([
      [ 'uuid', 'uuid' ],
      [ 'created_at', 'created_at' ],
      [ 'updated_at', 'updated_at' ]
    ]).sort do |(k1, _), (k2, _)|
      k1 <=> k2     # Ensure that the attributes are built in the right order
    end.map do |attribute, json|
      json_path = json.split('.')
      json_leaf = json_path.pop

      attribute_path = attribute.split('.').map(&:to_sym)
      attribute_leaf = attribute_path.pop
      %Q{
        handle_attribute(object, #{attribute_leaf.inspect}, #{attribute_path.inspect}, options) do |value, force|
          container = result
          #{json_path.inspect}.each do |k|
            break if container.nil?
            container = force ? (container[k] ||= {}) : container[k]
          end

          container[#{json_leaf.inspect}] = value unless container.nil?
        end
      }
    end

    # NOTE: Handy to have when debugging!
    low_level("#{'=' * 20} #{self.name} #{'=' * 20}")
    low_level("OUTPUT JSON CODE:")
    code.each(&method(:low_level))
    low_level('-' * 60)

    line = __LINE__ + 1
    class_eval(%Q{
      def self.object_json(object, uuids_to_ids, options)
        uuids_to_ids[object.uuid] = object.id

        super.tap do |result|
          #{code.join("\n")}
        end
      end
    }, "#{__FILE__}(#{self.name})", line)
  end

  RETURNED_OBJECTS = [
    Symbol, String, Fixnum, BigDecimal,
    Date, Time, ActiveSupport::TimeWithZone,
    FalseClass, TrueClass
  ]

  def jsonify(object, options)
    case
    when object.nil?         then nil
    when object.is_a?(Array) then object.map! { |o| jsonify(o, options) }
    when object.is_a?(Hash)  then Hash[object.map { |k,v| [ jsonify(k, options), jsonify(v, options) ] }]
    when RETURNED_OBJECTS.include?(object.class) then object
    else ::Core::Io::Registry.instance.lookup_for_object(object).as_json(options.merge(:object => object, :nested => true))
    end
  end
  private :jsonify

  def handle_attribute(object, attribute_name, attribute_path, options)
    target = attribute_path.inject(object) { |o,k| break if o.nil? ; o.send(k) }
    return yield(nil, false) if target.nil?
    yield(jsonify(target.send(attribute_name), options), true)
  end
  private :handle_attribute
end
