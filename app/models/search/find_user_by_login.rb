# frozen_string_literal: true
class Search::FindUserByLogin < Search
  def scope(criteria)
    User.with_login(criteria['login'])
  end
end
