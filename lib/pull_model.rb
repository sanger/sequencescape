require 'optparse'
$options = { :model => "sample"}
$objects = []

class ActiveRecord::Base
  def pull(includes=nil)
    return [] if @already_pulled
    @already_pulled = true
    pulled = [self]

    case includes
    when Array
      includes.each do |model|
        pulled += self.send(model).pull([])
      end
    when Hash
      includes.each do |model, options|
        pulled += self.send(model).pull(options)
      end
    end
    return pulled

  end
end

class Array
def pull(includes =nil)
  map {|e| e.pull(includes) }.flatten
end
end

optparse = OptionParser.new do |opts|
  opts.on('-s', '--sample id_or_name', 'sample to pull') do |sample|
    $objects<< [Sample, [:assets, :requests],  sample]
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
      loaded += object.pull(includes)
    end
  return loaded
  end
end

  ARGV.shift  # to remove the -- needed using script/runner
  optparse.parse!
  #puts $options.to_yaml
  #puts $objects.to_yaml

  puts load_objects($objects).to_yaml






