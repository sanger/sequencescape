# FasterCSV lets up stream to any IO that supports #<<(string)
# Unfortunately ActionController::Response only supports #write
# The two methods are typically aliases, so this lets us add support
class ActionController::Response
  alias_method :<<, :write
end
