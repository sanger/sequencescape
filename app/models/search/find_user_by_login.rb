# frozen_string_literal: true
class Search::FindUserByLogin < Search # rubocop:todo Style/Documentation
  def scope(criteria)
    User.with_login(criteria['login'])
  end
end
