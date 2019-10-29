module ROCrate
  class ContactPoint < Entity
    properties(%w[name email])

    private

    def default_properties
      super.merge('@type' => 'ContactPoint')
    end
  end
end
