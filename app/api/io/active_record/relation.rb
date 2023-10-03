# frozen_string_literal: true
class Io::ActiveRecord::Relation
  extend ::Core::Io::Collection

  class << self
    def as_json(options = {})
      options[:handled_by].generate_json_actions(
        options[:object],
        options.merge(target: options[:response].request.target)
      )
      super
    end

    def size_for(results)
      results.count
    end
    private :size_for
  end
end
