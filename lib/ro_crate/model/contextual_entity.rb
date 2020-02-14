module ROCrate
  ##
  # A class to represent a "Contextual Entity" within an RO Crate.
  # Contextual Entities are used to describe and provide context to the Data Entities within the crate.
  class ContextualEntity < Entity
    def self.format_id(id)
      i = super
      if (URI(i).absolute? rescue false)
        i
      elsif i.start_with?('#')
        i
      else
        "##{i}"
      end
    end
  end
end
