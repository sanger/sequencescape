# Provides the appearance of dynamically generated methods on the roles database.
#
# Examples:
#   user.is_member?                     --> Returns true if user has any role of "member"
#   user.is_member_of? this_workshop    --> Returns true/false. Must have authorizable object after query.
#   user.is_eligible_for [this_award]   --> Gives user the role "eligible" for "this_award"
#   user.is_moderator                   --> Gives user the general role "moderator" (not tied to any class or object)
#   user.is_candidate_of_what           --> Returns array of objects for which this user is a "candidate" (any type)
#   user.is_candidate_of_what(Party)    --> Returns array of objects for which this user is a "candidate" (only 'Party' type)
#
#   model.has_members                   --> Returns array of users which have role "member" on that model
#   model.has_members?                  --> Returns true/false
#
module Authorization
  module Identity
    VALID_PREPOSITIONS = %w[of for in on to at by].freeze
    BOOLEAN_OPS = %w[not or and].freeze
    VALID_PREPOSITIONS_PATTERN = VALID_PREPOSITIONS.join('|')
    module UserExtensions
      module InstanceMethods # rubocop:todo Style/Documentation
        def method_missing(method_sym, *args)
          method_name = method_sym.to_s
          authorizable_object = args.empty? ? nil : args[0]

          base_regex = 'is_(\\w+)'
          fancy_regex = base_regex + "_(#{Authorization::Identity::VALID_PREPOSITIONS_PATTERN})"
          is_either_regex = '^((' + fancy_regex + ')|(' + base_regex + '))'

          # matches is_role? and is_role_of?
          if method_name =~ Regexp.new(is_either_regex + '\?$')
            role_name = $3 || $6
            has_role?(role_name, authorizable_object)
          # matches is_role and is_role_of
          elsif method_name =~ Regexp.new(is_either_regex + '$')
            role_name = $3 || $6
            has_role(role_name, authorizable_object)
          else
            super
          end
        end
      end
    end
  end
end
