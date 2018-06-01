
module Core::Io::Base::EagerLoadingBehaviour
  def set_eager_loading
    singleton_class.class_eval do
      define_method(:eager_loading_for) do |loaded_class|
        yield(super(loaded_class))
      end
    end
  end

  def eager_loading_for(model)
    model or raise StandardError, 'nil model does not make sense here at all!'
  end
end
