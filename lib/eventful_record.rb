module EventfulRecord
  def has_many_events(&block)
    has_many(:events, :as => :eventful, :dependent => :destroy, :order => 'created_at') do
      def self.event_constructor(name, event_class, event_class_method)
        line = __LINE__ + 1
        class_eval(%Q{
          def #{name}(*args)
            #{event_class.name}.#{event_class_method}(self.proxy_owner, *args).tap { |event| self << event }
          end
        }, __FILE__, line)
      end

      class_eval(&block) if block.present?
    end
  end

  def has_many_lab_events(&block)
    has_many(:lab_events, :as => :eventful, :dependent => :destroy, :order => 'created_at', &block)
  end

  def has_one_event_with_family(event_family, &block)
    has_one(:"#{event_family}_event", :class_name => 'Event', :as => :eventful, :conditions => { :family => event_family }, :order => 'id DESC', &block)
  end
end
