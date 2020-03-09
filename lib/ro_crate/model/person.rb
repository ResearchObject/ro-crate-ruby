module ROCrate
  ##
  # A contextual entity that represents a person.
  class Person < ContextualEntity
    properties(%w[name familyName givenName identifier sameAs])

    private

    def default_properties
      super.merge('@type' => 'Person')
    end
  end
end
