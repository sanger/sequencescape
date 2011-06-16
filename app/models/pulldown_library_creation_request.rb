class PulldownLibraryCreationRequest < Request
  has_metadata :as => Request do
    attribute(:fragment_size_required_from, :required => true, :integer => true)
    attribute(:fragment_size_required_to,   :required => true, :integer => true)

    include BaitLibrary::Associations
    association(:bait_library, :name)
  end
end
