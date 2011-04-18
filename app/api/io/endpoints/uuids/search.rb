class ::Io::Endpoints::Uuids::Search
  def self.model_for_input
    ::Uuids::Search
  end

  def initialize(search)
    @search = search
  end

  def as_json(options = {})
    {}
  end

  def self.json_field_for(attribute)
    attribute
  end
end
