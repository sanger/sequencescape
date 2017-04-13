# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

module Submission::ProjectValidation
  def self.included(base)
    base.class_eval do
      # We probably want to move this validation
      validates_each(:project, if: :checking_project?) do |record, _attr, project|
        record.errors.add(:base, "Project #{project.name} is not approved")                 unless project.approved?
        record.errors.add(:base, "Project #{project.name} is not active")                   unless project.active?
        record.errors.add(:base, "Project #{project.name} does not have a budget division") unless project.actionable?
      end

      validates_each(:project, if: :validating?) do |record, _attr, project|
        record.errors.add(:base, "Project #{project.name} is not suitable for submission: #{project.errors.full_messages.join('; ')}") unless project.submittable?
      end

      after_create :confirm_validity!
    end
  end

  def complete_building
    check_project_details!
    super
  end

  def checking_project?
    validating? && project.enforce_quotas?
  end

  def validating?
    project && @checking_project
  end

  Error = Class.new(Exception)

  def check_project_details!
    raise Submission::ProjectValidation::Error, errors.full_messages.join("\n") unless submittable?
  end
  private :check_project_details!

  def multiplier_for(request_type)
    return 1 if request_options.blank? or not request_options.key?(:multiplier)
    request_options[:multiplier][request_type.id.to_i] || 1
  end
  private :multiplier_for

  def submittable?
    begin
      @checking_project = true
      valid?
    ensure
      @checking_project = false
    end
  end

  # Hack to be able to build order
  # from pulled data
  def save_after_unmarshalling
    @saving_without_validation = true
    save(validate: false)
    @saving_without_validation = false
  end

  def confirm_validity!
    return if @saving_without_validation
    check_project_details!
  end
  private :confirm_validity!
end
