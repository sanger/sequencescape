# frozen_string_literal: true
require 'rainbow'

# Provides the ability to create and manage views through ActiveRecord
# @see https://dev.mysql.com/doc/refman/5.7/en/create-view.html
module ViewsSchema
  # Warning displayed in the event that the views have been broken
  WARNING = <<~HEREDOC
    ╔════════════════════════════════════════════════════════════╗
    ║                          WARNING!                          ║
    ║        The attempt to dump the view schema failed.         ║
    ║ It is likely that your migrations have broken one or more  ║
    ║      of the views. It is CRITICAL that this problem is     ║
    ║       addressed before you commit these migrations.        ║
    ║   To ensure that reporting is not affected please ensure   ║
    ║    that the updated view accurately reflects the data.     ║
    ║    DO NOT change the schema of the view, merely how it     ║
    ║   retrieves the data. Ensure the changes are thoroughly    ║
    ║            tested against production like data.            ║
    ║                                                            ║
    ║      Downstream users should be notified of potential      ║
    ║                        disruption.                         ║
    ╚════════════════════════════════════════════════════════════╝
  HEREDOC

  # Valid algorithm options, first option is default
  ALGORITHMS = %w[UNDEFINED MERGE TEMPTABLE].freeze

  # Valid security options, first option is default
  SECURITIES = %w[DEFINER INVOKER].freeze
  VIEW_STATEMENT = '%{action} ALGORITHM=%<algorithm>s SQL SECURITY %<security>s VIEW `%<name>s` AS %<statement>s'

  # rubocop:todo Layout/LineLength
  REGEXP =
    /\ACREATE ALGORITHM=(?<algorithm>\w*) DEFINER=`[^`]*`@`[^`]*` SQL SECURITY (?<security>\w*) VIEW `[^`]+` AS (?<statement>.*)\z/i

  # rubocop:enable Layout/LineLength

  def self.each_view
    all_views.each do |name|
      query = ActiveRecord::Base.with_connection.exec_query("SHOW CREATE TABLE #{name}").first
      matched = REGEXP.match(query['Create View'])
      yield(name, matched[:statement], matched[:algorithm], matched[:security])
    end
  rescue ActiveRecord::StatementInvalid => e
    puts Rainbow(WARNING).red.inverse
    raise e
  end

  def self.all_views # rubocop:todo Metrics/MethodLength
    ActiveRecord::Base
      .connection
      .execute(
        "
      SELECT TABLE_NAME AS name
      FROM INFORMATION_SCHEMA.VIEWS
      WHERE TABLE_SCHEMA = '#{ActiveRecord::Base.with_connection.current_database}';"
      )
      .map do |v|
        # Behaviour depends on ruby version, so we need to work out what we have
        v.is_a?(Hash) ? v['name'] : v.first
      end
      .flatten
  end

  #
  # Creates a new view. Will fail if the view already exists.
  # @param name [String] The name of the view to create
  # @param statement [String,ActiveRecord::Relation] SQL select statement or equivalent rails relation object
  # @param algorithm [String] View algorithm to use, either UNDEFINED MERGE TEMPTABLE (default UNDEFINED)
  # @param security [String] View security to use, either DEFINER INVOKER (default DEFINER)
  #
  # @return [Void]
  def self.create_view(name, statement, algorithm: ALGORITHMS.first, security: SECURITIES.first)
    execute(action: 'CREATE', name: name, statement: statement, algorithm: algorithm, security: security)
  end

  #
  # Updates an existing view, or creates a new view if it doesn't exist already.
  # @param name [String] The name of the view to create
  # @param statement [String,ActiveRecord::Relation] SQL select statement or equivalent rails relation object
  # @param algorithm [String] View algorithm to use, either UNDEFINED MERGE TEMPTABLE (default UNDEFINED)
  # @param security [String] View security to use, either DEFINER INVOKER (default DEFINER)
  #
  # @return [Void]
  def self.update_view(name, statement, algorithm: ALGORITHMS.first, security: SECURITIES.first)
    execute(action: 'CREATE OR REPLACE', name: name, statement: statement, algorithm: algorithm, security: security)
  end

  #
  # Drops the view
  # @param name [String] The name of the view to drop
  #
  # @return [Void]
  def self.drop_view(name)
    raise "Invalid name: `#{args[:name]}`" unless /^[a-z0-9_]*$/.match?(args[:name])

    ActiveRecord::Base.with_connection.execute("DROP VIEW IF EXISTS `#{name}`;")
  end

  # Generates the SQL for view creation/updating
  # @note Use create_view or update_view
  #
  # @param args [Hash] The options for the new view
  # @option args [String] name The name of the view to create
  # @option args [String] action Whether to create or update, can be 'CREATE' or 'CREATE OR REPLACE'
  # @option args [String,ActiveRecord::Relation] statement SQL select statement or equivalent rails relation object
  # @option args [String] algorithm  View algorithm to use, either UNDEFINED MERGE TEMPTABLE (default UNDEFINED)
  # @option args [String] security View security to use, either DEFINER INVOKER (default DEFINER)
  def self.execute(args)
    raise "Invalid name: `#{args[:name]}`" unless /^[a-z0-9_]*$/.match?(args[:name])

    args[:statement] = args[:statement].to_sql if args[:statement].respond_to?(:to_sql)
    ActiveRecord::Base.with_connection.execute(VIEW_STATEMENT % args)
  end
end
