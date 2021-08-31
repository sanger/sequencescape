# frozen_string_literal: true
module FieldInfosHelper # rubocop:todo Style/Documentation
  def field_info_id(path, field)
    path = path.clone
    return field if path.empty?

    first = path.shift
    to_bracketize = path + [field.key] # , "value"]
    to_join = [first] + to_bracketize.map { |w| "[#{w}]" }
    to_join.join
  end

  def field_info_label(path, field)
    (path + [field.key]).join('_')
  end
end
