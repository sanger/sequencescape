module ProductHelpers
  def self.single_template(name)
    {
      name: name,
      selection_behaviour: 'SingleProduct',
      products: {
        nil => name
      }
    }
  end
end
