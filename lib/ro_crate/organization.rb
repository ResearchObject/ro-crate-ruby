module ROCrate
  class Organization < Node
    properties(['name'])

    private

    def default_properties
      super.merge('@type' => 'Organization')
    end
  end
end
