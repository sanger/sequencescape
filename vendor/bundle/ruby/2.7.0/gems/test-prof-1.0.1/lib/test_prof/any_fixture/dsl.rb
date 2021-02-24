# frozen_string_literal: true

module TestProf
  module AnyFixture
    # Adds "global" `fixture` method (through refinement)
    module DSL
      # Refine object, 'cause refining modules (Kernel) is vulnerable to prepend:
      # - https://bugs.ruby-lang.org/issues/13446
      # - Rails added `Kernel.prepend` in 6.1: https://github.com/rails/rails/commit/3124007bd674dcdc9c3b5c6b2964dfb7a1a0733c
      refine ::Object do
        def fixture(id, &block)
          ::TestProf::AnyFixture.register(:"#{id}", &block)
        end
      end
    end
  end
end
