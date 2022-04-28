# frozen_string_literal: true
# This class is due to be removed shortly.
# All references to it in the code have been removed.
# At a later date a migration will be written to update the
# StiType of all existing CherrypickForPulldownRequests to CherrypickRequest
# As well as updating request_class on request_types.
# @deprecated Use {CherrypickRequest} instead
class CherrypickForPulldownRequest < CherrypickRequest
end
