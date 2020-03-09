module ROCrate
  ##
  # A contextual entity that represents a contact point.
  class ContactPoint < ContextualEntity
    properties(%w[name email])

    private

    def default_properties
      super.merge('@type' => 'ContactPoint')
    end
  end
end
