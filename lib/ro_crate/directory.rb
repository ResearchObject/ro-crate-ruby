module ROCrate
  class Directory < Entity

    private

    def default_properties
      super.merge(
          '@id' => "./#{SecureRandom.uuid}/",
          '@type' => 'Dataset'
      )
    end
  end
end
