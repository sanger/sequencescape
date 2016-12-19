# A RequestStateChange can be used to pass library creation
# requests. It will also link the requests onto the correct
# wells of the target plate. It takes the following:
# target: The plate on which the library has been completed.
# user: the user performing tha action
# submissions: an array of submissions which will be passed.
# Requirements:
# The wells of the target plate are expected to have stock
# well_links to the plate on which the orignal library_creation
# requests were made. This provides a means of finding the library
# creation requests.
class RequestStateChange < ActiveRecord::Base
end
