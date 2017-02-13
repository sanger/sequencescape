# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module ::Core::Io::Base::JsonFormattingBehaviour::Output
  def json_code_tree
    ::Core::Io::Json::Grammar::Root.new(self)
  end
  private :json_code_tree

  def generate_object_to_json_mapping(attribute_to_json)
    # Sort the attribute_to_json map such that the JSON elements are in order, thus ensuring that
    # we will only open and close blocks as we go.  Then build a tree that can be executed against
    # an object to generate the JSON appropriately.
    tree = attribute_to_json.sort_by(&:last).map do |attribute, json|
      [json.split('.'), attribute.split('.').map(&:to_sym)]
    end.inject(json_code_tree.for(self)) do |tree, (json_path, attribute_path)|
      tree.tap do
        json_leaf = json_path.pop
        json_path.inject(tree) { |node, step| node[step] }.leaf(json_leaf, attribute_path)
      end
    end

    # Now we can generate a method that will use that tree to encode an object to JSON.
    singleton_class.send(:define_method, :json_code_tree) { tree }
    singleton_class.send(:define_method, :object_json, &tree.method(:encode))
  end
end
