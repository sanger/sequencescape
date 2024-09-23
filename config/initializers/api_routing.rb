# frozen_string_literal: true
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
    options = entities.extract_options!
    read_only = !options.key?(:read_only) || options.delete(:read_only)
    exposed_actions = read_only ? %i[index show] : %i[index show create update]
    entities.push({ only: exposed_actions, name_prefix: 'api_' }.merge(options))

    original_block = block
    block = !block_given? ? original_block : ->(r) { r.with_options(read_only:, &original_block) }
    resources(*entities, &block)
  end
end

class ActionDispatch::Routing::Mapper
  include ApiRouting
end
