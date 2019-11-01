module ROCrate
  class Organization < Entity
    properties(['name'])

    private

    def default_properties
      super.merge('@type' => 'Organization')
    end
  end
end
