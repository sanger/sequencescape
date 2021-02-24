# frozen_string_literal: true

require_relative "./base"

module TestProf
  module RSpecDissect
    module Collectors # :nodoc: all
      class Before < Base
        def initialize(params)
          super(name: :before, **params)
        end

        def print_name
          "before(:each)"
        end
      end
    end
  end
end
