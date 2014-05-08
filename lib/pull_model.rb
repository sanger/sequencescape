#!/usr/bin/env script/runner
require 'optparse'
require 'rgl/dot'
DOT=RGL::DOT

# Hack to work different version of sequencescape
begin
Aliquot

Asset
class Asset
  def sample
    nil
  end

  def tags
    []
  end

end
rescue
  class Aliquot < ActiveRecord::Base
    class Receptacle < Asset
    end
  end

  Asset
  class Asset
    def aliquots
      []
    end
  end
end

begin
  TagInstance
rescue
  class TagInstance < Asset
  end
end
  class TagInstance < Asset
    def sample
      nil
    end
  end
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
  def initialize(rankdir="LR")
    @rankdir = rankdir
  end

  def layouts
    Layouts[:submission]
  end
  def render(objects, options, &block)
    @root_object = Set.new(objects)
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
    edges.each do |edge|
      nodes << edge.parent
      nodes << edge.object unless edge.is_a?(HiddenEdge) or edge.is_a?(Ellipsis) or edge.is_a?(CutEdge)
      #nodes << edge.object unless edge.is_a?(HiddenEdge) or edge.is_a?(Ellipsis)
    end
    return nodes.to_a.compact
  end

  def construct_graph(nodes, edges)
    DOT::Graph.new("rankdir" =>@rankdir).tap do |graph|


      layouts.each do |layout|
        #layout.transform!(nodes, edges).each { |e| graph << e }
      end

      drawn_nodes = add_nodes(graph, nodes, edges)
      add_edges(graph, drawn_nodes, edges)

      #hack
      all_requests = drawn_nodes.select { |n| n.is_a?(Request)}
      all_requests = []

      all_requests.group_by(&:class).each do |klass, requests|
        subgraph = DOT::Subgraph.new("name" => "cluster_#{klass.name}", "style"=>"filled", "fillcolor"=>"gold", "color" => "goldenrod4")
        requests.each do |r|
          subsubgraph = DOT::Subgraph.new("name" => "cluster_#{r.node_name}", "color"=>"none")
          [r.asset.requests.size <=1 ? r.asset : nil, r, r.target_asset].compact.each do |o|
            subsubgraph << DOT::Node.new("name" => o.node_name)
            graph << subsubgraph
          end
        end
        graph << subgraph
      end
    end
  end

  def add_nodes(graph, major_nodes, edges)
    #normal node
    hidden = Set.new()
    normal = Set.new()
    cut = Set.new()
    ellipsis = Set.new()
    label_map = {}

    edges.each do |edge|

      set = case edge
            when Ellipsis then ellipsis
            when HiddenEdge then  hidden
            when CutEdge then cut
            else normal
           end
      set << edge.object
      label_map[edge.object] ||= edge.label if edge.object
    end

    cut += ellipsis
    cut -= normal
    hidden -= (cut + normal)

    done = Set.new()


    # Draw each node
    edges.each do |edge|
      [edge.parent, edge.object].each do |node|
        next if done.include?(node) or not node
        done << node
         node_options = node.try(:node_options)
        if label=label_map[node]
          node_options["label"] = label
        end
        dot_node = case
        when normal.include?(node)
         DOT::Node.new(node_options.merge("style" => "filled"))
        when ellipsis.include?(node)
         DOT::Node.new(node_options.merge("color" => "gray", "fontcolor" => "gray", "shape" => "roundbox"))
        when cut.include?(node)
         DOT::Node.new(node_options.merge("color" => "gray"))
        end
        next unless dot_node
         if @root_object.include?(node)
           dot_node.options.merge!( "penwidth" => "5")
         end
        graph << dot_node
      end
    end

    return cut+normal
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
    dot_edge.from = edge.parent.node_name
    dot_edge.to = edge.object.node_name
    return dot_edge
  end
end

# remove doulbon
class SingleGraphRenderer < GraphRenderer
  def add_edges(graph, nodes, edges)
    edge_set = Set.new()
    super(graph, nodes, edges.select { |e| edge_set.include?(e.key) == false and edge_set<< e.key and edge_set.include?(e.reversed_key) == false})
  end
end

class DigraphRenderer < GraphRenderer
  def construct_graph(nodes, edges)
    DOT::Digraph.new("rankdir" => "LR").tap do |graph|

      add_nodes(graph, nodes, edges)
      add_edges(graph, nodes, edges)
    end
  end

  def create_edge(edge)
    dot_edge = DOT::DirectedEdge.new(edge.edge_options)
    dot_edge.from = edge.parent.node_name
    dot_edge.to = edge.object.node_name
    return dot_edge
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
    #if @parent and @parent.is_a?(Request)
      #request = @parent
      #@name = request.class.name
      #if @object == request.asset
        #@parent = request.target_asset
      #elsif @object == request.target_asset
        #@parent = request.asset
      #end
    #elsif @object and @object.is_a?(Request) and (not @parent or @parent.is_a?(Asset))
      #request = @object
      #@name = request.class.name
      #if @parent == request.asset
        #@object = request.target_asset
      #elsif parent == request.target_asset
        #@object = request.asset
      #end
    #end
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
      "name" => object.node_name,
      "label" => label(),
      "style" => "filled"
    }
  end

  def edge_options
    case
      # Request related
    when object && object.is_a?(Request) && parent && parent.is_a?(Asset)
      { "color" => object.color, "style" => "bold", "dir" => "both"}.merge(
      if object.asset == parent # source side
        { "taillabel" => "", "arrowtail" => "dot", "arrowhead" => "empty", "sametail" => "source_#{parent.node_name}"}
      else
        { "taillabel" => "", "arrowtail" => "normal", "arrowhead" => "odot", "sametail" => "target_#{parent.node_name}"}
      end
      )
    when parent.is_a?(Request) && object && object.is_a?(Asset)
      { "color" => parent.color, "style" => "bold", "dir" => "both"}.merge(
      if parent.asset == object # source side
      {"headlabel" =>  "", "arrowtail" => "empty", "arrowhead" => "dot", "samehead" => "source_#{object.node_name}"}
      else
      {"headlabel" =>  "", "arrowhead" => "normal", "arrowtail" => "odot", "sametail" => "target_#{parent.node_name}"}
      end
      )
      # AssetLink
    when object.is_a?(Asset) && parent.is_a?(Asset)
        if parent and parent.parents.present? and parent.parents.include?(object)
          @parent, @object = [@object, @parent] # reverse so they could share the same 'sametail'
        end
      {"style" => "dashed", "dir" => "both"}.merge(
        {"arrowtail" => "odiamond", "arrowhead" => "empty", "sametail" => parent.node_name, "samehead" => object.node_name}
      )
      #Aliquot
    when object.is_a?(Aliquot) && parent.is_a?(Asset)
        {"arrowtail" => "odiamond", "arrowhead" => "empty", "sametail" => parent.node_name, "samehead" => object.node_name, "dir" => "both"}
    when parent.is_a?(Aliquot) && object.is_a?(Asset)
          @parent, @object = [@object, @parent] # reverse so they could share the same 'sametail'
        {"arrowtail" => "odiamond", "arrowhead" => "empty", "sametail" => parent.node_name, "samehead" => object.node_name, "dir"=> "both"}
    else
      {}
    end
  end

  # TODO  proably a ruby way to do it
  def key
    [parent, object]
  end

  # the key of the reversed edge, not necessarily the reverse of the key
  def reversed_key
    [object, parent]
  end

end

class CutEdge < Edge
  def node_options
    super.merge({ "color" => "red", "style" => "none"})
  end

  def edge_options
    super.merge("constraint" => "true", "color" => "gray")
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

class NodeToCluster
  def initialize(*args)
    @classes = args
  end
  #we could return new nodes and edges, but we modify them instead ... evil
  def  transform!(nodes, edges)
    clusters = []
    selected_nodes = nodes.select { |n| @classes.any? { |c| n.is_a?(c) } }

    #create a cluster for each node
    selected_nodes.each do | node|
      cluster_name = "luster_#{node.node_name}"
      cluster = DOT::Subgraph.new("name" => cluster_name, "label" => node.node_name, "fillcolor" => "yellow", "color" => "lightcyan", "style"=>"filled")
      cluster << DOT::Node.new("name" => node.node_name)
      clusters << cluster
      #node.instance_eval "def node_name(); '#{cluster_name}'; end"

        edges.each do |edge|
        next if edge.is_a?(HiddenEdge)
          #debugger  if edge.parent == node

          #i edge.parent == node and edge.object and nodes.include?(edge.object) #!edge.is_a?(HiddenEdge)
          if edge.parent == node and edge.object and !edge.is_a?(HiddenEdge)
            cluster << DOT::Node.new("name" => edge.object.node_name)
          else if edge.object == node and edge.parent and !edge.is_a?(HiddenEdge)
            cluster << DOT::Node.new("name" => edge.parent.node_name)
          end
            edges.delete(edge)
          end
        end

        nodes.delete(node)
    end
    clusters
  end
end


# Model descriptions can be specified for subclass.
# use :skip_super to not include superclass association
Models = {
  :submission => [{
  Submission => [:study, :project, RequestByType=lambda { |s|  s.requests.group_by(&:request_type_id).values }, :asset_group],
  Request => [:asset, :target_asset],
  Asset => [lambda { |s|  s.requests.group_by(&:request_type_id).values }, :requests_as_target, :children, :parent],
  AssetGroup => [:assets]
},
  {
  Request => [:submission]
}
],

  :simple_submission =>  { Submission => lambda { |s|  s.requests.group_by(&:request_type_id).values }} ,

  :asset_down => AssetDown={ Asset => [:children, RequestByType, :sample, :tags],
    Request => [:target_asset],
    Submission => [RequestByType],
    Aliquot::Receptacle => [:aliquots],
    Aliquot => [:sample, :tag],
    Plate => [:wells]
},
  :asset_up => AssetUp={ Asset => [:parents, :requests_as_target],
    TagInstance => [:tag],
    Request => [:asset],
    Aliquot => [:sample, :tag],
    Aliquot::Receptacle => [:aliquots],
    Well => [:plate]},
  :sample_with_assets => AssetDown.merge(
  Sample => [:assets, :study_samples],
  StudySample => [:study],
  Asset => [:requests, :children, :parents],
  Well => [:container_association],
  ContainerAssociation => [:container, :content] ,
  Request => [:submission, :asset,:item,  :target_asset, :request_metadata, :user],
  Submission => [:asset_group]
),
  :asset_up_and_down => [AssetUp, AssetDown],
  :asset_down_and_up => [AssetDown, AssetUp],
  :full_asset => AssetUp.merge(AssetDown),
  :asset => [{Asset => [ lambda { |s|  s.requests.group_by(&:request_type_id).values },
        :requests_as_target, :children, :parents]},
        { Request => [:asset, :target_asset]}],
  :submission_down => [{ Submission => RequestByType}.merge(AssetDown)] ,
    :bare => {}
}

Layouts =  { :submission => [ NodeToCluster.new(Submission)
  ]
}
optparse = OptionParser.new do |opts|
  opts.on('-e', '--eval expr ', 'ruby expression returning a list of object to pull') do |expr|
    $objects<< expr
  end
  opts.on('-s', '--sample id_or_name', 'sample to pull') do |sample|
    $objects<< [Sample, sample]
  end

  opts.on('--study id_or_name', 'study to pull') do |study|
    $objects<< [Study, study]
  end

  opts.on('-a', '--asset id_or_name', 'asset to pull') do |asset|
    $objects<< [Asset, asset]
  end

  opts.on('-a', '--request id', 'request to pull') do |request|
    $objects<< [Request, request]
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
  opts.on('-rs', '--ruby', 'Generate a ruby script') do
    $options[:output_method] = ScriptRenderer.new
  end

  opts.on('-g', '--graph type', 'Generate a dot graph') do |type|
    $options[:output_method] = SingleGraphRenderer.new
    set_graph_filter_option(type)
  end
  opts.on('--graph_down type', 'Generate a dot graph') do |type|
    $options[:output_method] = SingleGraphRenderer.new("TB")
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
                           if index == 1 and max_index > 1
                             # things been removed
                             RubyWalk::Cut.new(Ellipsis.new(parent, object, index, max_index))
                           else
                             Edge.new(parent, object, index, max_index) if [0,max_index].include?(index) or not parent
                           end
                         end
                       when "3center"
                         Proc.new do |object, parent, index, max_index|
                           # cut everything but one
                           kept_index = [1, max_index || 0].min
                           kept_index = index unless parent
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
  objects.each do |object|
    case object
    when Array
    model, name = object
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
    when String
      loaded = eval(object)
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

def find_model(model_name)
    model = Models[model_name.to_sym]
    raise "can't find model #{model_name}. Available models are #{Models.keys.inspect}" unless model
    model
end

ARGV.shift  # to remove the -- needed using script/runner
optparse.parse!
#puts $options.to_yaml
#puts $objects.to_yaml
#

#---------------
# reopening existing class for graph


class ActiveRecord::Base
  def node_name()
      "#{self.class}##{self.id}"
  end
  def node_options()
    { "name" => node_name }
  end
end

[Submission, Project,Study, Tag].each do |klass|
  klass.class_eval do
    #include ProjectLike
  def node_options_with_lyellow()
    node_options_without_lyellow.merge("shape" => "note", "fillcolor" => "lightyellow")
  end
  alias_method_chain :node_options, :lyellow
  end
end

[Asset].each do |klass|
  klass.class_eval do
    def node_options_with_lcyan()
      node_options_without_lcyan.merge("fillcolor" => "lightcyan")
    end
    alias_method_chain :node_options, :lcyan
  end
end
[Well].each do |klass|
  klass.class_eval do
    def node_options_with_well()
      node_options_without_well.merge("shape" => "septagon")
    end
    alias_method_chain :node_options, :well
  end
end
[Plate].each do |klass|
  klass.class_eval do
    def node_options_with_parallel()
      node_options_without_parallel.merge("shape" => "parallelogram")
    end
    alias_method_chain :node_options, :parallel
  end
end
[PulldownMultiplexedLibraryTube, MultiplexedLibraryTube, LibraryTube].each do |klass|
  klass.class_eval do
    def node_options_with_invt()
      node_options_without_invt.merge("shape" => "invtrapezium")
    end
    alias_method_chain :node_options, :invt
  end
end
[AssetGroup].each do |klass|
  klass.class_eval do
    def node_options_with_tab()
      node_options_without_tab.merge("shape" => "tab")
    end
    alias_method_chain :node_options, :tab
  end
end

[Request].each do |klass|
  klass.class_eval do
    def node_options_with_rect()
      node_options_without_rect.merge("shape" => "rectangle")
    end
    alias_method_chain :node_options, :rect
  end
end

begin
  TagInstance
rescue
  class TagInstance
    def node_options
      {}
    end
  end
end
[TagInstance, Sample, Tag].each do |klass|
  klass.class_eval do
    def node_options_with_fillcolor()
      node_options_without_fillcolor.merge("fillcolor" => "darkorange")
    end
    alias_method_chain :node_options, :fillcolor
  end
end
[Aliquot].each do |klass|
  klass.class_eval do
    def node_options_with_cyan()
      node_options_without_cyan.merge("fillcolor" => tag ? "deepskyblue3" : "dodgerblue")
    end
    alias_method_chain :node_options, :cyan
  end
end
[Well, MultiplexedLibraryTube].each do |klass|
  klass.class_eval do
    def node_options_with_multi
      node_options_without_multi.merge("fillcolor" => aliquots.size > 1 ? "red": "lightcyan")
    end
    alias_method_chain :node_options, :multi
  end
end
class Request
  def color()
    {"passed" => "green4", "failed" => "firebrick4", "pending" => "dodgerblue4", "started" => "darkorchid4"}.fetch(state, "gray22")
  end
  def node_options_with_state_color()
    node_options_without_state_color.merge("fontcolor" => color() )
  end
  alias_method_chain :node_options, :state_color
end

class Asset

  has_many :requests_as_target, :class_name => 'Request', :foreign_key => :target_asset_id, :include => :request_metadata
end



puts $options[:output_method].render(load_objects($objects), find_model($options[:model]), &($options[:block]))
