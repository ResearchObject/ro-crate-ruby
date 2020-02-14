module ROCrate
  class Organization < ContextualEntity
    properties(['name'])

    private

    def default_properties
      super.merge('@type' => 'Organization')
    end
  end
end
