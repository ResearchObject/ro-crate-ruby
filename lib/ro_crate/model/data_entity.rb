module ROCrate
  ##
  # A class to represent a "Data Entity" within an RO Crate.
  # Data Entities are the actual physical files and directories within the Crate.
  class DataEntity < Entity
    def self.format_id(id)
      super.chomp('/')
    end

    ##
    # Return an appropriate specialization of DataEntity for the given type.
    # @param type [String, Array<String>] Type (or types) from the JSON-LD @type property.
    # @return [Class]
    def self.specialize(type)
      type = [type] unless type.is_a?(Array)
      if type.include?('Dataset')
        ROCrate::Directory
      else
        ROCrate::File
      end
    end

    ##
    # A map of all the files/directories associated with this DataEntity.
    #
    # @return [Hash{String => Entry}>] The key is the location within the crate, and the value is an Entry.
    def entries
      {}
    end

    ##
    # A disk-safe filepath based on the ID of this DataEntity.
    #
    # @return [String] The relative file path of this DataEntity within the Crate.
    def filepath
      Addressable::URI.unescape(id.sub(/\A\//, '')).to_s # Remove initial / and decode %20 etc.
    end
  end
end
