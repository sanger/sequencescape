module ManifestUtil
  def is_end_of_header?(row, pos)
    ((pos!=(row.length-1)) && row[pos].nil? && row[pos+1].nil?)
  end

  def filter_end_of_header(header_row)
    found_end_of_header = false
    header_row.reject.each_with_index do |value, pos|
      found_end_of_header ||= is_end_of_header?(header_row, pos)
    end
  end
end
