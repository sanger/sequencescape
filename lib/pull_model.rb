require 'optparse'
$options = {:output_method => :objects_to_yaml, :model => :sample_with_assets}
$objects = []
$already_pulled = {}

class ActiveRecord::Base
  def to_pull
    []
  end
  def pull()
    #check if object has already been pulled
    key = [self.class.table_name, self.id]
    return [] if $already_pulled.include?(key)
    $already_pulled[key] = true

    pulled = []
    self.to_pull.each do |model|
      pulled += self.send(model).pull()
    end
    return pulled << self
  end
end

class Array
  def pull()
    map {|e| e.pull() }.flatten
  end
end

class NilClass
  def pull()
    []
  end
end

# Model descriptions can be specified for subclass. use :super to call include superclass definitions
Models = {
  :sample_with_assets =>  {
    Sample => [:assets, :study_samples],
    StudySample => [:study],
    Asset => [:requests, :children, :parents],
    Request => [:submission, :asset, :target_asset, :request_metadata, :user],
    Submission => [:asset_group]
  }
}
optparse = OptionParser.new do |opts|
  opts.on('-s', '--sample id_or_name', 'sample to pull') do |sample|
    $objects<< [Sample, sample]
  end

  opts.on '-m' '--model', 'model of what needs to be pull' do |model_name|
    $options[:model]=model_name
  end
  opts.on('-r', '--ruby', 'Generate a ruby script') do 
    $options[:output_method] = :objects_to_script
  end
end

def load_objects(objects)
  loaded = []
  objects.each do |model, name|
    name.split(",").each do |name|
      if name =~ /\A\d+\Z/
        #name is an id
        object =  model.find_by_id(name)
      elsif name =~ /\A:(first|last)\Z/
        object = model.find(name)
      else
        object = model.find_by_name(name)
      end

      raise RuntimeError, "can't find #{model} '#{name}'" unless object
      loaded << object
    end
  end
  return loaded
end

def object_to_hash(object)
  att =object.attributes.reject { |k,v| [ :created_at, :updated_at ].include?(k.to_sym) }
  att.each do |k,v|
    if k =~ /name|login|email|decription|abstract|title/i and v.is_a?(String)
      att[k] = "#{object.class.name}_#{object.id}_#{k}"
    end
  end
  att
end
def objects_to_script(objects)
  objects.map do |object|
    att = object_to_hash(object)
%Q{
#{object.class.name}.new(#{att.inspect}) { |r| r.id = #{object.id} }.save_without_validation
}
  end
end

def objects_to_yaml(objects)
  objects.map do |object|
    att = object_to_hash(object)
    {:class => object.class.name, :id => object.id, :attributes => att}
  end.to_yaml
end

def install_model(model_name)
    model = Models[model_name]
    raise "can't find model #{model_name}. Available models are #{Models.keys.inspect}" unless model

    model.each do |klass, list|
      klass.class_eval <<-EOC
        def to_pull
          list = #{list.inspect}
          if list.delete(:super)
            list.concat(super)
          end
          list
        end
        EOC
    end
end
ARGV.shift  # to remove the -- needed using script/runner
optparse.parse!
#puts $options.to_yaml
#puts $objects.to_yaml

install_model($options[:model])


puts send($options[:output_method], load_objects($objects).pull)
