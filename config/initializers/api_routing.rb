# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

# TODO: Fix these
module ApiRouting
  # Assets have a couple of extra actions that are always present: namely 'parents' and 'children'
  def asset(*entities, &block)
    options = entities.extract_options!
    entities.push({ member: { parents: :get, children: :get } }.merge(options))
    model(*entities, &block)
  end

  # Models exposed through the API are assumed to always be read only, unless otherwise specified.  Nested
  # resources inherit the read only status of their parent.
  def model(*entities, &block)
    options   = entities.extract_options!
    read_only = !options.key?(:read_only) || options.delete(:read_only)
    exposed_actions = read_only ? [:index, :show] : [:index, :show, :create, :update]
    entities.push({ only: exposed_actions, name_prefix: 'api_' }.merge(options))

    original_block = block
    block          = !block_given? ? original_block : ->(r) { r.with_options(read_only: read_only, &original_block) }
    resources(*entities, &block)
  end
end

class ActionDispatch::Routing::Mapper
  include ApiRouting
end
