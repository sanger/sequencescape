class BarcodeLabel
  @@labels = []

  def self.labels
    @@labels
  end 

  def initialize_with_instance_store(options = {})
    initialize_without_instance_store(options = {})
    @@labels << self
  end
  alias_method_chain(:initialize, :instance_store)

  attr_accessor :number, :study, :suffix, :output_plate_purpose, :prefix

  def initialize(options = {})
    unless options.nil?
      @number = options[:number]
      @study = options[:study]
      @suffix = options[:suffix]
      @prefix= options[:prefix]
      if !options[:batch].nil? && !options[:batch].output_plate_purpose.nil?
        @output_plate_purpose = options[:batch].output_plate_purpose.name  
      end
    end
  end

end
