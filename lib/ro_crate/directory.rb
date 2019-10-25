module ROCrate
  class Directory < Node

    private

    def default_properties
      super.merge('@type' => 'Dataset')
    end
  end
end
