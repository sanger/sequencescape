class ContainerAssociation < ActiveRecord::Base
  #We don't define the class, so will get an error if being used directly
  # in fact , the class need to be definend otherwise, eager loading through doesn't work
  belongs_to :container , :class_name => "Asset"
  belongs_to :content , :class_name => "Asset"

  # An object can only be contained once
  validates_uniqueness_of :content_id
  validates_presence_of :container_id
  validates_presence_of :content_id

  module Extension
    def contains(content_name)
      class_name = content_name ? content_name.to_s.singularize.capitalize : Asset.name
      has_many :container_associations, :foreign_key => :container_id
      has_many :contents, :class_name => class_name, :through => :container_associations
      alias_attribute content_name, :contents if content_name

      named_scope :"include_#{content_name}", :include => :contents  do
        def to_include
          [:contents]
        end

        def with(subinclude)
          scoped(:include => { :contents => subinclude })
        end
      end
    end

    def contained_by(container_name)
      class_name = container_name.to_s.singularize.capitalize
      has_one :container_association, :foreign_key => :content_id
      has_one :container, :class_name => class_name, :through => :container_association
      has_one container_name, :class_name => class_name, :through => :container_association, :source => :container

      #delegate :location, :to => :container

      before_save do |content|
        # We check if the parent has already been saved. if not the saving will not work.
        container = content.container
        raise RuntimeError, "Container should be saved befor saving #{self.inspect}" if container && container.new_record?
      end
    end
  end
end
