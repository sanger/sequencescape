require "net/ldap"
require "openssl"
require "digest/sha1"
require 'curb'

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
  has_many :batches

  before_save :encrypt_password
  before_create { |record| record.new_api_key if record.api_key.blank? }
  before_create { |record| record.workflow ||= Submission::Workflow.default_workflow }

  validates_presence_of :login
  validates_confirmation_of :password, :if => :password_required?

  named_scope :with_login, lambda { |*logins| { :conditions => { :login => logins.flatten } } }

  acts_as_authorized_user

  attr_accessor :password

  def self.prefix
    'ID'
  end

  def study_roles
    self.user_roles("Study")
  end

  def project_roles
    self.user_roles("Project")
  end

  def study_and_project_roles
    study_roles | project_roles
  end

  def user_roles(authorizable_class_name)
    self.roles.find_all_by_authorizable_type(authorizable_class_name)
  end

  def following?(item)
    self.has_role? 'follower', item
  end

  def logout_path
    if configatron.authentication == "sanger-sso"
      return "#{configatron.sso_logout_url}"
    else
      return "/logout"
    end
  end

  def profile_incomplete?
    name_incomplete? or email.blank?
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
    name_incomplete? ? self.login : "#{self.first_name} #{self.last_name}"
  end

  def projects
    return Project.all if self.is_administrator?

    authorized_projects = []

    self.project_roles.each do |role|
      next if role.authorizable_id.nil?
      project = Project.find_by_id(role.authorizable_id)
      next if project.nil?
      authorized_projects << project
    end

    return Project.all if ( (authorized_projects.blank?) && (privileged?) )

    authorized_projects
  end

  def sorted_project_names_and_ids
    self.projects.sort_by(&:name).map{|p| [p.name, p.id] }
  end
  def sorted_valid_project_names_and_ids
    self.projects.select(&method(:valid_project)).sort_by(&:name).map{|p| [p.name, p.id] }
  end
  def valid_project(project)
    project.active? && project.approved?
  end
  private :valid_project

  def sorted_study_names_and_ids
    self.interesting_studies.sort_by(&:name).map{|p| [p.name, p.id] }
  end
  def workflow_name
    self.workflow and self.workflow.name
  end

  def has_preference_for(key)
    setting_for?(key)
  end

  def privileged?(item=nil)
    privileged = false
    privileged = true if manager_or_administrator?
    unless item.nil?
      privileged = true if self.owner?(item)
    end
    privileged
  end

  def internal?
    self.has_role? 'internal'
  end

  def lab_manager?
    self.has_role? 'lab_manager'
  end

  def slf_manager?
    self.has_role? 'slf_manager'
  end

  def slf_gel?
    self.has_role? 'slf_gel'
  end

  def lab?
    self.has_role? 'lab'
  end

  def owner?(item)
    self.has_role? 'owner', item
  end

  def manager_or_administrator?
    access = false
    if self.is_administrator? || self.is_manager?
      access = true
    end
    access
  end

  # Checks if the current user is a manager
  def manager?
    self.is_manager?
  end

  # Checks if the current user is an administrator
  def administrator?
    self.is_administrator?
  end

  # returns all administrator users
  def self.all_administrators
    role = Role.find_by_name('administrator')
    role ? role.users : []
  end

  # returns emails of all admins
  def self.all_administrators_emails
    self.all_administrators.map(&:email).compact.uniq
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def new_api_key(length = 32)
    u = Digest::SHA1.hexdigest(self.login)[0..12]
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
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # User has a relationship by role to these studies
  def interesting_studies
    Study.of_interest_to(self)
  end

  def self.valid_barcode?(code)
    begin
      human_code = Barcode.barcode_to_human!(code, self.prefix)
    rescue
      return false
    end
    return false unless User.find_by_barcode(human_code)

    true
  end

  def self.lookup_by_barcode(user_barcode)
    barcode = Barcode.barcode_to_human(user_barcode)
    if barcode
      return User.find_by_barcode(barcode)
    end

    nil
  end

  def self.owners
    all.select{ |user| user.is_owner? && ! user.last_name.blank? }.sort{ |user1, user2| user1.last_name <=> user2.last_name }
  end

  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end

end
