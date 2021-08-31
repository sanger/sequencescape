# frozen_string_literal: true
# ObjectSpaceProfile provides a tool for assessing how many Ruby objects are in
# memory. By taking measures over time you can watch the change in the number of
# objects, and identify situations in which we're holding on to more objects
# than intended. Sometimes it may be necessary to generate a report with each
# cycle, especially if performance means you aren't getting to the end of the
# process.
# @example
#   def method_we_are_profiling
#     osp = ObjectSpaceProfile.new
#     Record.each_batch do |batch|
#       ops.measure
#       do_stuff
#     end
#     osp.report('my_data.csv')
#   end
class ObjectSpaceProfile
  attr_reader :data

  def initialize
    @data = []
  end

  #
  # Take an object space reading
  #
  # @param [Boolean] garbage_collect Whether to perform garbage collection before taking a reading.
  #                                  slower, but will avoid the typical sawtooth profile.
  def measure(garbage_collect = true)
    ObjectSpace.garbage_collect if garbage_collect
    profile = Hash.new { |store, class_name| store[class_name] = 0 }
    ObjectSpace.each_object do |o|
      # This handles ALL objects, including anything that inherits from
      # BasicObject, or redefines class. (Ie. configatron)
      name = Kernel.instance_method(:class).bind_call(o).name
      profile[name] += 1
    end
    @data << profile
  end

  # Export the collected information to the csv file named filename
  # @param [String] filename The csv file to generate (In the application base directory)
  def report(filename)
    CSV.open(filename, 'wb', headers: headers, write_headers: true) do |csv|
      @data.each_with_index { |data, index| csv << data.merge({ 'Iteration' => index }) }
    end
  end

  private

  def headers
    ['Iteration'] + @data.flat_map(&:keys).uniq
  end
end
