#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.


# Advanced Product Criteria can have 'unprocessable' thresholds
# as well as fails.
class ProductCriteria::Advanced < ProductCriteria::Basic

  attr_reader :qc_decision

  STATE_ORDER = ['failed','unprocessable']

  def invalid(attribute,message,decision)
    @qc_decision = decision
    @comment << message % attribute.to_s.humanize
    @comment.uniq!
  end

  def assess!
    @qc_decision = 'passed'
    STATE_ORDER.each do |decision|
      params.fetch(decision,[]).each do |attribute,comparisons|
        value = fetch_attribute(attribute)
        values[attribute] = value

        if value.blank? && comparisons.present?
          invalid(attribute,'%s has not been recorded',decision)
          next
        end

        comparisons.each do |comparison,target|
          value.send(method_for(comparison),target) || invalid(attribute,message_for(comparison),decision)
        end
      end
    end
  end
end
