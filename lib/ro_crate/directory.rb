module ROCrate
  class Directory < Entity

    private

    def default_properties
      super.merge('@type' => 'Dataset')
    end
  end
end
