module Billing
  module Factory
    def self.build(request)
      return Sequencing.new(request: request) if request.billing_product.sequencing?
      return LibraryCreation.new(request: request) if request.billing_product.library_creation?

      Base.new(request: request)
    end
  end
end
