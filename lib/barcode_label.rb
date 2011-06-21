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


  def barcode_name
    # at that point we should probably remove the first to chars of the study if its LE
    # but the old code doesn't do it, maybe a bug
    # for now, we keep the old (buggy) code behavior
    name = study ?  study.gsub("_", " ").gsub("-"," ") : nil
  end
  def barcode_description
    "#{barcode_name}_#{barcode_number}"
  end

  def barcode_prefix(default_prefix)
    #todo move upstream
    prefix || begin 
      p = study[0..1]
      p == "LE" ? p : default_prefix
    end
  end

  def barcode_number
    number.to_i
  end

  def barcode_text(default_prefix)
      barcode_text = "#{barcode_prefix(default_prefix)} #{number.to_s}"
  end


end
