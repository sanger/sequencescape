# frozen_string_literal: true

FactoryBot.define do
  # Converts i to base 4, then substitutes in ATCG to
  # generate unique tags in sequence
  sequence :oligo do |i|
    i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')
  end

  factory :tag, aliases: [:tag2] do
    tag_group
    oligo
    map_id { 1 }
  end

  factory :tag_group do
    sequence(:name) { |n| "Tag Group #{n}" }

    transient do
      tag_count { 0 }
      adapter_type_name { nil }
    end

    adapter_type { build(:adapter_type, name: adapter_type_name) if adapter_type_name }

    after(:build) do |tag_group, evaluator|
      evaluator.tag_count.times { |i| tag_group.tags << create(:tag, map_id: i + 1, tag_group:) }
    end

    factory :tag_group_with_tags do
      transient { tag_count { 5 } }
    end
  end

  factory(:tag_group_form_object, class: 'TagGroup::FormObject') do
    skip_create

    sequence(:name) { |n| "Tag Group #{n}" }

    transient { oligos_count { 0 } }

    after(:build) do |tag_group_form_object, evaluator|
      if evaluator.oligos_count.positive?
        o_list =
          Array.new(evaluator.oligos_count) do |i|
            # generates a series of 8-character oligos
            (16_384 + i).to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')
          end
        tag_group_form_object.oligos_text = o_list.join(' ')
      end
    end

    factory :tag_group_form_object_with_oligos do
      transient { oligos_count { 5 } }
    end
  end

  factory :adapter_type, class: 'TagGroup::AdapterType' do
    sequence(:name) { |i| "Adapter #{i}" }
  end
end
