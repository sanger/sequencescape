# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'net/ldap'
require 'openssl'
require 'digest/sha1'
# require 'curb'

class User < ActiveRecord::Base
  include Authentication
  include Workflowed
  extend EventfulRecord
  include Uuid::Uuidable
  include Swipecardable
  has_many_events

  has_many :lab_events
  has_many :items
  has_many :requests
  has_many :comments
  has_many :settings
  has_many :roles
  has_many :submissions
  has_many :project_roles, ->() { where(authorizable_type: 'Project') }, class_name: 'Role'
  has_many :study_roles,   ->() { where(authorizable_type: 'Study') },   class_name: 'Role'
  has_many :study_roles
  has_many :batches
  has_many :assigned_batches, class_name: 'Batch', foreign_key: :assignee_id, inverse_of: :assignee
  has_many :pipelines, ->() { order('batches.id DESC').distinct }, through: :batches

  before_save :encrypt_password
  before_create { |record| record.new_api_key if record.api_key.blank? }
  before_create { |record| record.workflow ||= Submission::Workflow.default_workflow }

  validates_presence_of :login
  validates_uniqueness_of :login

  validates_confirmation_of :password, if: :password_required?

  scope :with_login, ->(*logins) { where(login: logins.flatten) }
  scope :all_administrators, -> { joins(:roles).where(roles: { name: 'administrator' }) }

  acts_as_authorized_user

  scope :owners, ->() { where.not(last_name: nil).joins(:roles).where(roles: { name: 'owner' }).order(:last_name).uniq }

  attr_accessor :password

  def self.prefix
    'ID'
  end

  def study_roles
    user_roles('Study')
  end

  def project_roles
    user_roles('Project')
  end

  def study_and_project_roles
    roles.where(authorizable_type: ['Study', 'Project'])
  end

  def user_roles(authorizable_class_name)
    roles.where(authorizable_type: authorizable_class_name)
  end

  def following?(item)
    has_role? 'follower', item
  end

  def logout_path
    if configatron.authentication == 'sanger-sso'
      (configatron.sso_logout_url).to_s
    else
      '/logout'
    end
  end

  def profile_incomplete?
    name_incomplete? or email.blank? or swipecard_code.blank?
  end

  def profile_complete?
    not profile_incomplete?
  end

  def name_incomplete?
    first_name.blank? or last_name.blank?
  end

  def name_complete?
    not name_incomplete?
  end

  def name
    name_incomplete? ? login : "#{first_name} #{last_name}"
  end

  def projects
    return Project.all if is_administrator?
    atuhorized = authorized_projects
    return Project.all if ((atuhorized.blank?) && (privileged?))
    atuhorized
  end

  def authorized_projects
    Project.for_user(self)
  end

  def sorted_project_names_and_ids
    projects.alphabetical.pluck(:name, :id)
  end

  def sorted_valid_project_names_and_ids
    valid_projects.pluck(:name, :id)
  end

  def valid_projects
    projects.valid.alphabetical
  end

  def sorted_study_names_and_ids
    interesting_studies.alphabetical.pluck(:name, :id)
  end

  def workflow_name
    workflow && workflow.name
  end

  def has_preference_for(key)
    setting_for?(key)
  end

  def privileged?(item = nil)
    manager_or_administrator? || owner?(item)
  end

  def internal?
    has_role? 'internal'
  end

  def qa_manager?
    has_role? 'qa_manager'
  end

  def lab_manager?
    has_role? 'lab_manager'
  end

  def slf_manager?
    has_role? 'slf_manager'
  end

  def slf_gel?
    has_role? 'slf_gel'
  end

  def lab?
    has_role? 'lab'
  end

  def owner?(item)
    return false if item.nil?
    has_role? 'owner', item
  end

  def data_access_coordinator?
    has_role? 'data_access_coordinator'
  end

  def manager_or_administrator?
    is_administrator? || is_manager?
  end

  def manager?
    is_manager?
  end

  def administrator?
    is_administrator?
  end

  # returns emails of all admins
  def self.all_administrators_emails
    all_administrators.pluck(:email).compact.uniq
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def new_api_key(length = 32)
    u = Digest::SHA1.hexdigest(login)[0..12]
    k = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..length]
    self.api_key = "#{u}-#{k}"
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(validate: false)
  end

  # User has a relationship by role to these studies
  def interesting_studies
    Study.of_interest_to(self)
  end

  def self.valid_barcode?(code)
    begin
      human_code = Barcode.barcode_to_human!(code, prefix)
    rescue
      return false
    end
    return false unless User.find_by(barcode: human_code)

    true
  end

  def self.lookup_by_barcode(user_barcode)
    barcode = Barcode.barcode_to_human(user_barcode)
    if barcode
      return User.find_by(barcode: barcode)
    end

    nil
  end

  protected

    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end
end
