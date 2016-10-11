# While the traditional linefeed in window is CR-LF vs LF
# in unix, excel seems to be generating spreadsheets with
# CR-CR-LF, which CSV.parse doesn't like.
module LinefeedFix
  # Replaces consecutive CR and LF characters with a single
  # lineffed character. Warning! Mutates the original string.
  def self.scrub!(string)
    string.gsub!(/[\r\n]+/,"\n")
  end
end
