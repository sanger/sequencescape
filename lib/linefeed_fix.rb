# frozen_string_literal: true
# While the traditional linefeed in window is CR-LF vs LF
# in unix, excel seems to be generating spreadsheets with
# CR-CR-LF, which CSV.parse doesn't like.
module LinefeedFix
  # Converts windows \r\n linefeeds to \r
  # also handles odd \r\r\n seen at the end of some excel
  # generated csvs
  def self.scrub!(string)
    string.gsub!(/\r{0,1}\r\n/, "\n")
    string
  end
end
