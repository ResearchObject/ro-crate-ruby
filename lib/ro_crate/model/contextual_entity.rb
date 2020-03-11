module ROCrate
  ##
  # A class to represent a "Contextual Entity" within an RO Crate.
  # Contextual Entities are used to describe and provide context to the Data Entities within the crate.
  class ContextualEntity < Entity
    def self.format_id(id)
      i = super
      begin
        uri = URI(id)
      rescue ArgumentError
        uri = nil
      end

      if uri&.absolute?
        i
      elsif i.start_with?('#')
        i
      else
        "##{i}"
      end
    end

    ##
    # Return an appropriate specialization of ContextualEntity for the given type.
    # @param type [String, Array<String>] Type (or types) from the JSON-LD @type property.
    # @return [Class]
    def self.specialize(type)
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
