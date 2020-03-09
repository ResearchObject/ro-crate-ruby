module ROCrate
  ##
  # A contextual entity that represents an organization.
  class Organization < ContextualEntity
    properties(['name'])

    private

    def default_properties
      super.merge('@type' => 'Organization')
    end
  end
end
