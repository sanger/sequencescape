# frozen_string_literal: true

module Core::Io::Base::EagerLoadingBehaviour
  def set_eager_loading
    singleton_class.class_eval { define_method(:eager_loading_for) { |loaded_class| yield(super(loaded_class)) } }
  end

  def eager_loading_for(model)
    model or raise StandardError, 'nil model does not make sense here at all!'
  end
end
