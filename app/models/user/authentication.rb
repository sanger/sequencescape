# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

module User::Authentication
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      extend Ldap
      extend Local
    end
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def update_profile_via_ldap
    ldap = Net::LDAP.new(host: configatron.ldap_server, port: configatron.ldap_port)

    filter = Net::LDAP::Filter.eq('uid', login)
    treebase = 'ou=people,dc=sanger,dc=ac,dc=uk'

    ldap_profile = ldap.search(base: treebase, filter: filter)[0]
    # If we have two or more records, something is off with LDAP

    { email: 'mail', first_name: 'givenname', last_name: 'sn' }.each do |attr, ldap_attr|
      self[attr] = ldap_profile[ldap_attr][0] if self[attr].blank?
    end
    save if changed?

  rescue StandardError => e
    logger.error "Profile failed for user #{login}: result code #{ldap.get_operation_result.code} message #{ldap.get_operation_result.message} - #{e}"
  end
  private :update_profile_via_ldap

  module ClassMethods
    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      if configatron.authentication == 'ldap'
        authenticated = authenticate_with_ldap(login, password)
        authenticated ? register_or_update_via_ldap(login) : nil
      else
        authenticated = authenticate_by_local(login, password)
      end
    end
  end

  module Ldap
    def authenticate_with_ldap(login, password)
      # TODO: - Extract LDAP specifics to configuration
      username = 'uid=' << login << ',ou=people,dc=sanger,dc=ac,dc=uk'
      ldap = Net::LDAP.new(
          host: configatron.ldap_server,
          port: configatron.ldap_secure_port,
          encryption: :simple_tls,
          auth: {
            method: :simple,
            username: username,
            password: password
          }
      )
      begin
        ldap.bind
      rescue StandardError => e
        raise e, "LDAP connection problem: #{e}", caller
      end
      password = '' # clear out in case of crashes
      if ldap.bind
        logger.info 'Authentication succeeded'
        true
      else
        logger.warn "Authentication failed for user #{login}: result code #{ldap.get_operation_result.code} message #{ldap.get_operation_result.message}"
        false
      end
    end

    def register_or_update_via_ldap(login)
      u = find_or_create_by(login: login)
      if u.nil?
        logger.error "Failed to find or create user #{login}"
      else
        u.send(:update_profile_via_ldap) unless u.profile_complete?
      end
      u
    end
  end

  module Local
    def authenticate_by_local(login, password)
      u = find_by(login: login) # need to get the salt
      u && u.authenticated?(password) ? u : nil
    end
  end
end
