# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012 Genome Research Ltd.
require 'xml/libxml'

class XML::Node
  ##
  # Open up XML::Node from libxml and add convenience methods inspired
  # by hpricot.
  # (http://code.whytheluckystiff.net/hpricot/wiki/HpricotBasics)
  # Also:
  #  * provide better handling of default namespaces

  # an array of default namespaces to past into
  attr_accessor :default_namespaces

  # find the child node with the given xpath
  def at(xpath)
    find_first(xpath)
  end

  # find the array of child nodes matching the given xpath
  def search(xpath)
    results = find(xpath).to_a
    if block_given?
      results.each do |result|
        yield result
      end
    end
    results
  end

  # alias for search
  def /(xpath)
    search(xpath)
  end

  # return the inner contents of this node as a string
  def inner_xml
    child.to_s
  end

  # alias for inner_xml
  def inner_html
    inner_xml
  end

  # return this node and its contents as an xml string
  def to_xml
    to_s
  end

  # alias for path
  def xpath
    path
  end

  # provide a name for the default namespace
  def register_default_namespace(name)
    namespace.each do |n|
      if n.to_s == nil
        register_namespace("#{name}:#{n.href}")
        return
      end
    end
    raise 'No default namespace found'
  end

  # register a namespace, of the form "foo:http://example.com/ns"
  def register_namespace(name_and_href)
    (@default_namespaces ||= []) << name_and_href
  end

  def find_with_default_ns(xpath_expr, namespace = nil)
    find_base(xpath_expr, namespace || default_namespaces)
  end

  def find_first_with_default_ns(xpath_expr, namespace = nil)
    find_first_base(xpath_expr, namespace || default_namespaces)
  end

  alias_method :find_base, :find unless method_defined?(:find_base)
  alias_method :find, :find_with_default_ns

  alias_method :find_first_base, :find_first unless method_defined?(:find_first_base)
  alias_method :find_first, :find_first_with_default_ns
end

class String
  def to_libxml_doc
    xp = XML::Parser.new
    xp.string = self
    xp.parse
  end
end
