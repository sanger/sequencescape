#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IlluminaC::StockPurpose < PlatePurpose
  include PlatePurpose::Stock

  def transition_to(plate, state, contents = nil,customer_accepts_responsibility=false)
    return unless ['failed','cancelled'].include?(state)
    plate.wells.located_at(contents).each do |well|
      well.requests.each {|r| r.send(transition_from(r.state)) if r.is_a?(IlluminaC::Requests::LibraryRequest) }
      well.requests_as_target.each {|r| r.transition_to('failed') if r.is_a?(TransferRequest)}
    end
  end

  def transition_from(state)
    {'pending' => :cancel_before_started!, 'started'=>:cancel!}[state]
  end
  private :transition_from
end
