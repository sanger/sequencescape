# frozen_string_literal: true
require 'net/ldap'
require 'openssl'
require 'digest/sha1'

# Represents Sequencescape users, used to regulate login as well as provide tracking of who did what.
# While most users are internal, some are external.
class User < ApplicationRecord # rubocop:todo Metrics/ClassLength
  include Authentication
  extend EventfulRecord
  include Uuid::Uuidable
  include Swipecardable
  include Role::UserRoleHelper
  has_many_events

  has_many :lab_events
  has_many :items
  has_many :requests
  has_many :comments
  has_many :settings
  has_many :user_role_bindings, class_name: 'Role::UserRole'
  has_many :roles, through: :user_role_bindings
  has_many :submissions
  has_many :batches
  has_many :assigned_batches, class_name: 'Batch', foreign_key: :assignee_id, inverse_of: :assignee
  has_many :pipelines, -> { order('batches.id DESC').distinct }, through: :batches

  has_many :consent_withdrawn_sample_metadata,
           class_name: 'Sample::Metadata',
           foreign_key: 'user_id_of_consent_withdrawn',
           inverse_of: :user_of_consent_withdrawn

  before_save :encrypt_password
  before_create { |record| record.new_api_key if record.api_key.blank? }

  validates :login, presence: true, uniqueness: { case_sensitive: false }
  validates :password, confirmation: { if: :password_required? }

  scope :with_login, ->(*logins) { where(login: logins.flatten) }
  scope :all_administrators, -> { joins(:roles).where(roles: { name: 'administrator' }) }

  scope :owners,
        lambda { where.not(last_name: nil).joins(:roles).where(roles: { name: 'owner' }).order(:last_name).distinct }

  scope :with_user_code,
        lambda { |*codes|
          where(barcode: codes.filter_map { |code| Barcode.barcode_to_human(code) }).or(with_swipecard_code(codes))
        }

  attr_accessor :password

  # Other DSL
  # See {Role::UserRoleHelper::has_role}
  # Provides methods like: user.administrator?, user.grant_administrator
  # @note Where possible use permissions, not roles to define abilities.
  # @see Ability
  has_role :administrator
  has_role :manager
  has_role :lab_manager
  has_role :lab
  has_role :owner
  has_role :slf_manager
  has_role :qa_manager
  has_role :slf_gel
  has_role :follower
  has_role :data_access_coordinator

  def self.prefix
    'ID'
  end

  def self.find_with_barcode_or_swipecard_code(user_code)
    with_user_code(user_code).first
  end

  # returns emails of all admins
  def self.all_administrators_emails
    all_administrators.uniq.pluck(:email).compact
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def self.sequencescape
    find_or_create_by!(login: configatron.sequencescape_email, email: configatron.sequencescape_email)
  end

  def study_and_project_roles
    roles.where(authorizable_type: %w[Study Project])
  end

  def logout_path
    configatron.authentication == 'sanger-sso' ? configatron.sso_logout_url.to_s : '/logout'
  end

  def profile_incomplete?
    name_incomplete? || email.blank? || swipecard_code.blank?
  end

  def profile_complete?
    not profile_incomplete?
  end

  def name_incomplete?
    first_name.blank? || last_name.blank?
  end

  def name_complete?
    not name_incomplete?
  end

  def name
    name_incomplete? ? login : "#{first_name} #{last_name}"
  end

  def name_and_login
    "#{first_name} #{last_name} (#{login})".strip
  end

  def valid_projects
    projects.valid.alphabetical
  end

  def sorted_study_names_and_ids
    interesting_studies.alphabetical.pluck(:name, :id)
  end

  def manager_or_administrator?
    administrator? || manager?
  end

  def new_api_key(length = 32)
    u = Digest::SHA1.hexdigest(login)[0..12]
    k = Digest::SHA1.hexdigest(Time.zone.now.to_s + rand(12_341_234).to_s)[1..length]
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
    self.remember_token = encrypt("#{email}--#{remember_token_expires_at}")
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token = nil
    save(validate: false)
  end

  # User has a relationship by role to these studies
  def interesting_studies
    Study.of_interest_to(self)
  end

  protected

  # before filter
  def encrypt_password
    return if password.blank?

    self.salt = Digest::SHA1.hexdigest("--#{Time.zone.now}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || password.present?
  end
end
