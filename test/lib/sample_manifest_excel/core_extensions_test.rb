require_relative '../../test_helper'

class CoreExtensionsTest < ActiveSupport::TestCase

  test "hash#combine should combine key of hash with other hash without destroying any elements" do
    this_hash = {a: {a: 1, b: 2}, b: {c: 3, d: 4}, let_me_in: {bingo: {a: nil, b: nil, c: { a: 1, b: 2}}}}
    other_hash = {bingo: {a: {b: 1, c: 2}, b: {d: 3, e: 4}, c: {f: 6, g: 7}}, bongo: {a: 1, b: 2, c: 3}}
    combined_hash = {a: {a: 1, b: 2}, b: {c: 3, d: 4}, let_me_in: {bingo: {a: {b: 1, c: 2}, b: {d: 3, e: 4}, c: { a: 1, b: 2, f: 6, g: 7}}}}

    assert_equal combined_hash, this_hash.combine_by_key(other_hash, :let_me_in)

    assert_equal combined_hash.with_indifferent_access, this_hash.with_indifferent_access.combine_by_key(other_hash, :let_me_in)
  end
end