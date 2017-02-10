# Base class for the all tube purposes
class Tube::Purpose < ::Purpose
  # TODO: change to purpose_id
  has_many :tubes, foreign_key: :plate_purpose_id

  # Tubes of the general types have no stock plate!
  def stock_plate(_)
    nil
  end

  def library_source_plates(_)
    []
  end

  def created_with_request_options(tube)
    tube.creation_request.try(:request_options_for_creation) || {}
  end

  def create!(*args, &block)
    target_class.create_with_barcode!(*args, &block).tap { |t| tubes << t }
  end

  def sibling_tubes(_tube)
    nil
  end

  # Define some simple helper methods
  class << self
    ['stock', 'standard'].each do |purpose_type|
      ['sample', 'library', 'MX'].each do |tube_type|
        name = "#{purpose_type} #{tube_type}"

        line = __LINE__ + 1
        class_eval(%Q{
          def #{name.downcase.gsub(/\W+/, '_')}_tube
            find_by_name('#{name.humanize}') or raise "Cannot find #{name} tube"
          end
        }, __FILE__, line)
      end
    end
  end
end
