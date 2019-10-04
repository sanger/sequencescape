# Was used to extend {BarcodePrinter} with methods which were supposed to be specific to the
# V1 API. Now redundant
# @note JG: I believe this file can just be deleted. Only reason I'm not doing it now
#       is to try and keep this branch almost exclusively documentation related.
# @todo Delete this file. It doesn't even appear to be included in {BarcodePrinter}
module ModelExtensions::BarcodePrinter
  def self.included(base)
    base.class_eval do
      # TODO: Add an associations or named_scopes required
    end
  end

  # TODO: Add any instance methods required
end
