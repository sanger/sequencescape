require 'optparse'
$options = { :model => "sample"}
$objects = []
$already_pulled = {}

class ActiveRecord::Base
  def pull(includes=nil, &block)
    #debugger if id == 57422
    key = [self.class.table_name, self.id]
    return [] if $already_pulled.include?(key)
    $already_pulled[key] = true
    pulled = [block ? block.call(self) : self ]

    case includes
    when Array
      includes.each do |model|
        pulled += self.send(model).pull([], &block)
      end
    when Hash
      includes.each do |model, options|
        pulled += self.send(model).pull(options, &block)
      end
    when nil
    else
      pulled += self.send(includes).pull([],  &block)
    end
    return pulled
  end

end

class Array
def pull(includes =nil, &block)
  map {|e| e.pull(includes, &block) }.flatten
end
end

optparse = OptionParser.new do |opts|
  opts.on('-s', '--sample id_or_name', 'sample to pull') do |sample|
    #$objects<< [Sample, {},  sample]
    $objects<< [Sample, {:assets => { :requests => [:submission, :target_asset, :request_metadata], :children => :requests, :parents => :requests }, :study_samples =>  :study},  sample]
  end
  opts.on('--sample_with_metada id_or_name', 'sample to pull') do |sample|
    $objects<< [Sample, {:assets => { :requests => [:submission, :target_asset], :children => :requests, :parents => :requests }, :studies => nil, :sample_metadata => nil },  sample]
  end
  opts.on('-m', '--model', 'model (classname) of the object to pull') do |model|
    $options[:model]=model
  end

  opts.on('-i', '--id', 'id of the object to pull') do |id|
    $options[:id]=id
  end

  opts.on('-n', '--name', 'name of the object to pull') do |name|
    $options[:name]=name
  end
end

def load_objects(objects)
loaded = []
  objects.each do |model, includes,  name|
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
      loaded += object.pull(includes) do |object|
        att =object.attributes.reject { |k,v| [ :created_at, :updated_at ].include?(k.to_sym) }
        att["name"] = "#{object.class.name}_#{object.id}" if att.include?("name")
%Q{
#{object.class.name}.new(#{att.inspect}) { |r| r.id = #{object.id} }.save_without_validation
}
      end
    end
  return loaded
  end
end

  ARGV.shift  # to remove the -- needed using script/runner
  optparse.parse!
  #puts $options.to_yaml
  #puts $objects.to_yaml

puts load_objects($objects) 
