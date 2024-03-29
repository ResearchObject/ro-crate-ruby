module ROCrate
  ##
  # A class to represent a "Contextual Entity" within an RO-Crate.
  # Contextual Entities are used to describe and provide context to the Data Entities within the crate.
  class ContextualEntity < Entity
    def self.format_local_id(id)
      super(id.start_with?('#') ? id : "##{id}")
    end

    ##
    # Return an appropriate specialization of ContextualEntity for the given properties.
    # @param props [Hash] Set of properties to try and infer the type from.
    # @return [Class]
    def self.specialize(props)
      type = props['@type']
      type = [type] unless type.is_a?(Array)
      if type.include?('Person')
        ROCrate::Person
      elsif type.include?('Organization')
        ROCrate::Organization
      elsif type.include?('ContactPoint')
        ROCrate::ContactPoint
      else
        self
      end
    end
  end
end
