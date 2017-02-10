# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.

class Submission::PresenterSkeleton
  class_attribute :attributes, instance_writer: false
  self.attributes = Array.new

  def initialize(user, submission_attributes = {})
    submission_attributes = {} if submission_attributes.blank?

    @user = user

    attributes.each do |attribute|
      send("#{attribute}=", submission_attributes[attribute])
    end
  end

  # id accessors need to be explicitly defined...
  def id
    @id
  end

  def id=(submission_id)
    @id = submission_id
  end

  def lanes_of_sequencing
    return lanes_from_request_options if %{building pending}.include?(submission.state)
    lanes_from_request_counting
  end

  def cross_compatible?
  end

  def order_studies
    if order.study
      yield(order.study.name, order.study)
    else # Cross study
      Study.in_assets(order.all_assets).each do |study|
        yield(study.name, study)
      end
    end
  end

  def order_projects
    if order.project
      yield(order.project.name, order.project)
    else # Cross Project
      Project.in_assets(order.all_assets).each do |project|
        yield(project.name, project)
      end
    end
  end

  def each_submission_warning(&block)
    submission.each_submission_warning(&block)
  end

  def lanes_from_request_options
    return order.request_options.fetch(:multiplier, {}).values.last || 1 if order.request_types[-2].nil?

    sequencing_request = RequestType.find(order.request_types.last)
    multiplier_hash = order.request_options.fetch(:multiplier, {})
    sequencing_multiplier = (multiplier_hash[sequencing_request.id.to_s] || multiplier_hash.fetch(sequencing_request.id, 1)).to_i

    if order.multiplexed?
      sequencing_multiplier
    else
      order.assets.count * sequencing_multiplier
    end
  end
  private :lanes_from_request_options

  def lanes_from_request_counting
    submission.requests.where_is_a?(SequencingRequest).count
  end
  private :lanes_from_request_counting

  def method_missing(name, *args, &block)
    name_without_assignment = name.to_s.sub(/=$/, '').to_sym
    return super unless attributes.include?(name_without_assignment)

    instance_variable_name = :"@#{name_without_assignment}"
    return instance_variable_get(instance_variable_name) if name_without_assignment == name.to_sym
    instance_variable_set(instance_variable_name, args.first)
  end
  protected :method_missing
end
