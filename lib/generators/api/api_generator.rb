class ApiGenerator < Rails::Generator::NamedBase
  def banner
    "Usage: #{$0} #{spec.name} ModelName [create] [update]"
  end

  def singular_human_name
    self.singular_name.gsub(/_/, ' ')
  end

  def plural_human_name
    self.plural_name.gsub(/_/, ' ')
  end

  def can_create?
    actions.include?('create')
  end

  def can_update?
    actions.include?('update')
  end

  def belongs_to_associations
    reflections(:belongs_to) do |name|
      { :json => name.to_s }
    end
  end

  def has_many_associations
    reflections(:has_many) do |name|
      { :json => name.to_s, :to => name.to_s, :include => [] }
    end
  end

  IGNOREABLE_ATTRIBUTES = [ :id, :created_at, :updated_at ]

  def attributes
    # Reject any attributes that are either automatically output or belong to an association.
    names = model.column_names.map(&:to_sym).reject(&IGNOREABLE_ATTRIBUTES.method(:include?)).map(&:to_s)
    names = names - model.reflections.keys.map { |c| "#{c}_id" }

    # Now ensure that the justification is such that it fits the nice output format!
    max_length_name = names.map(&:size).max
    names.map { |s| [ s.rjust(max_length_name), s ] }
  end

  def reflections(type, &block)
    model.reflections.map do |name, reflection|
      case
      when name.to_sym == :uuid_object     then nil
      when reflection.macro != type.to_sym then nil
      else [ name.to_sym, yield(name) ]
      end
    end.compact.sort { |(a,_),(b,_)| a.to_s <=> b.to_s }
  end
  private :reflections

  def model
    singular_name.classify.constantize
  end

  def manifest
    record do |manifest|
      manifest.directory("app/api/endpoints")
      manifest.directory("app/api/io")
      manifest.directory("app/api/model_extensions")
      manifest.directory("features/api")

      manifest.template('endpoint.rb',      "app/api/endpoints/#{plural_name}.rb")
      manifest.template('io.rb',            "app/api/io/#{singular_name}.rb")
      manifest.template('extension.rb',     "app/api/model_extensions/#{singular_name}.rb")
      manifest.template('cucumber.feature', "features/api/#{plural_name}.feature")

      manifest.readme('WHAT-TO-DO-NEXT')
    end
  end
end
