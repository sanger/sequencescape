# Convenient mechanism for queueing the creation of AssetLink instances where there is
# singular parent with lots of children.
class AssetLink::Job < AssetLink::BuilderJob
  def initialize(parent, children)
    super(children.map { |child| [parent.id, child.id] })
  end
end
