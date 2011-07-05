#!/usr/bin/env script/runner
require 'optparse'
$options = {:output_method => :objects_to_yaml, :model => :sample_with_assets}
$objects = []
$already_pulled = {}


# Model descriptions can be specified for subclass.
# use :skip_super to not include superclass association
Models = {
  :sample_with_assets =>  {
    Sample => [:assets, :study_samples],
    StudySample => [:study],
    Asset => [:requests, :children, :parents],
    Well => [:container_association],
    ContainerAssociation => [:container, :content] ,
    Request => [:submission, :asset,:item,  :target_asset, :request_metadata, :user],
    Submission => [:asset_group]
  },
  :submission => {
    Submission => [:study, :project, :requests, :asset_group]
  },
  :bare => {}
}

optparse = OptionParser.new do |opts|
  opts.on('-s', '--sample id_or_name', 'sample to pull') do |sample|
    $objects<< [Sample, sample]
  end

  opts.on('--study id_or_name', 'study to pull') do |study|
    $objects<< [Study, study]
  end

  opts.on('--submission id_or_name', 'submission to pull') do |submission|
    $objects << [Submission, submission]
  end

  opts.on('-rt','--request_type', 'request types') do |request_types|
    $objects<< [RequestType, request_types]
  end

  opts.on '-m' '--model', 'model of what needs to be pull' do |model_name|
    $options[:model]=model_name
  end
  opts.on('-r', '--ruby', 'Generate a ruby script') do 
    $options[:output_method] = :objects_to_script
  end

  opts.on('-g', '--graph', 'Generate a dot graph') do
    $options[:output_method] =:objects_to_graph
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
    if k =~ /name|login|email|decription|abstract|title/i and v.is_a?(String) and (k !~ /class_?name/)
      att[k] = "#{object.class.name}_#{object.id}_#{k}"
    end
  end
  att.reject { |k,v| !v }
end
def objects_to_script(objects)
  objects.map do |object|
    att = object_to_hash(object)
%Q{
#{object.class.name}.new(#{att.inspect}) { |r| r.id = #{object.id} }.save_without_validation
}
  end
end

def objects_to_graph(objects)
  objects.map do |object|
    "#{object.class.name} #{object.id}"
  end
end

def objects_to_yaml(objects)
  objects.map do |object|
    att = object_to_hash(object)
    {:class => object.class.name, :id => object.id, :attributes => att}
  end.to_yaml
end

def find_model(model_name)
    model = Models[model_name.to_sym]
    raise "can't find model #{model_name}. Available models are #{Models.keys.inspect}" unless model
    model
end

ARGV.shift  # to remove the -- needed using script/runner
optparse.parse!
#puts $options.to_yaml
#puts $objects.to_yaml



puts send($options[:output_method], load_objects($objects).walk_objects(find_model($options[:model] )))
