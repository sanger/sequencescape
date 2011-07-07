#!/usr/bin/env script/runner
require 'optparse'
require 'rgl/dot'
DOT=RGL::DOT

#TODO put in a module
class Renderer
  def render(objects, options, &block)
         render_objects(objects.walk_objects(options, &block))
  end
end

class ScriptRenderer < Renderer
  def render_object(objects)
    objects.map do |object|
      att = object_to_hash(object)
        %Q{
            #{object.class.name}.new(#{att.inspect}) { |r| r.id = #{object.id} }.save_without_validation
          }
    end
  end
end


class GraphRenderer < Renderer
  def render(objects, options, &block)
    options = [options] unless options.is_a?(Array)

    nodes, edges = options.inject([objects, []]) do |ne, option|
      nodes, old_edges = ne
      new_edges = nodes.walk_objects(option, &block)
      new_nodes = extract_used_objects_from_edges(new_edges)

      [new_nodes, old_edges + new_edges]
    end

    construct_graph(nodes, edges).to_s
  end

  def extract_used_objects_from_edges(edges)
    nodes = Set.new()
    edges.reject{ |e| e.is_a?(HiddenEdge)}.each do |edge|
      nodes << edge.parent
      nodes << edge.object
    end
    return nodes.delete(nil)
  end

  def construct_graph(nodes, edges)
    DOT::Graph.new("rankdir" => "LR").tap do |graph|

      add_nodes(graph, nodes, edges)
      add_edges(graph, nodes, edges)
    end
  end

  def add_nodes(graph, major_nodes, edges)
    #normal node
    hidden = Set.new()
    normal = Set.new()
    cut = Set.new()
    label_map = {}
    
    edges.each do |edge|

      set = case edge
            when HiddenEdge then  hidden
            when CutEdge then cut
            else normal
           end
      set << edge.object
      label_map[edge.object] ||= edge.label if edge.object
    end

    cut -= normal
    hidden -= (cut + normal)

    done = Set.new()


    # Draw eache node
    edges.each do |edge|
      [edge.parent, edge.object].each do |node|
        next if done.include?(node) or not node
        done << node
         node_options = { "name" => node_name(node) }
        if label=label_map[node]
          node_options["label"] = label
        end
        dot_node = case 
        when normal.include?(node)
         DOT::Node.new(node_options.merge("style" => "filled"))
        when cut.include?(node)
         DOT::Node.new(node_options.merge("color" => "gray"))
        end
        next unless dot_node
        graph << dot_node
      end
    end
  end

  def add_edges(graph, nodes, edges)
    edges.each do |edge|
      next unless edge.parent and edge.object
      next if edge.is_a?(HiddenEdge) and  not nodes.include?(edge.object)

      graph << create_edge(edge)
    end
  end

  def create_edge(edge)
    dot_edge = DOT::Edge.new(edge.edge_options)
    dot_edge.from = node_name(edge.parent)
    dot_edge.to = node_name(edge.object)
    return dot_edge
  end
end

# remove doulbon
class SingleGraphRenderer < GraphRenderer
  def add_edges(graph, nodes, edges)
    edge_set = Set.new(edges.map(&:key))
    super(graph, nodes, edges.select { |e| edge_set.include?(e.reversed_key) == false})
  end
end

class DigraphRenderer < GraphRenderer
  def construct_graph(nodes, edges)
    DOT::Diraph.new("rankdir" => "LR").tap do |graph|

      add_nodes(graph, nodes, edges)
      add_edges(graph, nodes, edges)
    end
  end
end
class YamlRenderer < Renderer
  def render_objects(objects)
    objects.map do |object|
      att = object_to_hash(object)
      {:class => object.class.name, :id => object.id, :attributes => att}
    end.to_yaml
  end
end

$options = {:output_method => YamlRenderer.new, :model => :sample_with_assets}
$objects = []
$already_pulled = {}

class Edge
  attr_reader :parent, :object, :index, :max_index
  def initialize(*args)
    @parent, @object, @index, @max_index = args
  end

  def label()
    if index
      "#{index+1}/#{max_index+1} - #{object.class.name}# #{object.id}"
    else
      "#{object.class.name}# #{object.id}"
    end
  end

  def node_options
    {
      "name" => node_name(object),
      "label" => label(),
      "style" => "filled"
    }
  end

  def edge_options
    {}
  end

  # TODO  proably a ruby way to do it
  def key
    [parent, object]
  end

  def reversed_key
    [object, parent]
  end

end

class CutEdge < Edge
  def node_options
    super.merge({ "color" => "red", "style" => "none" })
  end
end

class  HiddenEdge < CutEdge
end

class Ellipsis < CutEdge
  def label
     #"#{[max_index+1-3, 1].max} x #{object.class.name}"
     " ... x #{object.class.name}"
  end
end


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
    Submission => [:study, :project, lambda { |s|  s.requests.group_by(&:request_type_id).values }, :asset_group],
    Request => [:asset, :target_asset],
    Asset => lambda { |s|  s.requests.group_by(&:request_type_id).values },
    AssetGroup => [:assets]
  },
    :simple_submission =>  { Submission => lambda { |s|  s.requests.group_by(&:request_type_id).values }} ,
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
    $options[:output_method] = ScriptRendere.new
  end

  opts.on('-g', '--graph type', 'Generate a dot graph') do |type|
    $options[:output_method] = SingleGraphRenderer.new
    set_graph_filter_option(type)
  end
  opts.on('-d', '--digraph type', 'Generate a dot graph') do |type|
    $options[:output_method] = DigraphRenderer.new
    set_graph_filter_option(type)
  end
end

def set_graph_filter_option(type)
    $options[:block] = case type
                       when "full"
                         Proc.new do |object, parent, index, max_index|
                             Edge.new(parent, object, index, max_index)
                         end
                       when "3max"
                         Proc.new do |object, parent, index, max_index|
                           if index == 2 and max_index > 2
                             # things been removed
                             RubyWalk::Cut.new(Ellipsis.new(parent, object, index, max_index))
                           else
                             Edge.new(parent, object, index, max_index) if [0,1,max_index].include?(index)
                           end
                         end
                       when "3center"
                         Proc.new do |object, parent, index, max_index|
                           # cut everything but one
                           kept_index = [1, max_index || 0].min
                           case index || kept_index
                           when kept_index
                             Edge.new(parent, object, index, max_index)
                           when 0,max_index
                               # things been removed
                               #RubyWalk::Cut.new({ parent => [object, object.class.name]})
                               RubyWalk::Cut.new(CutEdge.new(parent,object, index, max_index))
                           when 2
                               #RubyWalk::Cut.new({ parent => [object, "..."]})
                               RubyWalk::Cut.new(Ellipsis.new(parent,object, index, max_index))
                           else 
                               RubyWalk::Cut.new(HiddenEdge.new(parent, object, index, max_index))
                           end
                         end
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
def node_name(object)
  "#{object.class}##{object.id}"
end



def objects_to_graph(edges)
  edges  = edges.map(&:to_a).map(&:first)
  DOT::Graph.new("rankdir" => "LR").tap do |graph|
    node_map =  {}

    #create the node first
    edges.each do |edge|
      next unless edge.object
      hidden = false
      next if edge.is_a?(HiddenEdge)
      node = DOT::Node.new(edge.node_options)
      node_map[edge.object] = node
      graph << node
    end
    edge_map= {}
    edges.each do |edge|
      next if edge_map[edge.reversed_key]
      next unless edge.parent and edge.object
      next if edge.is_a?(HiddenEdge) and  not node_map[edge.object]
      dot_edge = DOT::Edge.new(edge.edge_options)
      dot_edge.from = node_map[edge.parent].name
      dot_edge.to = node_map[edge.object].name
      graph << dot_edge
      edge_map[edge.key] = true
    end
  end
end
def objects_to_digraph(edges)
  edges  = edges.map(&:to_a).map(&:first)
  DOT::Digraph.new("rankdir" => "LR").tap do |graph|
    node_map =  {}

    #create the node first
    edges.each do |parent, object|
      next unless object
      next if object.is_a?(Hidden)
      if object.is_a?(Array)
        node = DOT::Node.new("label" => object[1], "name" => node_name(object[0]))
      else
        node = DOT::Node.new("name" => node_name(object), "style"=>"filled")
      end
      node_map[object] = node
      graph << node
    end
    edges.each do |parent, object|
      next if object.is_a?(Hidden)
      next unless parent and object
      edge = DOT::DirectedEdge.new
      edge.from = node_map[parent].name
      edge.to = node_map[object].name
      graph << edge
    end
  end
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

puts $options[:output_method].render(load_objects($objects), find_model($options[:model]), &($options[:block]))
