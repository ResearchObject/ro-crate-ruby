module ROCrate
  ##
  # A class to represent a "Data Entity" within an RO-Crate.
  # Data Entities are the actual physical files and directories within the Crate.
  class DataEntity < Entity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs author])

    def self.format_local_id(id)
      super.chomp('/')
    end

    ##
    # Return an appropriate specialization of DataEntity for the given properties.
    # @param props [Hash] Set of properties to try and infer the type from.
    # @return [Class]
    def self.specialize(props)
      type = props['@type']
      type = [type] unless type.is_a?(Array)
      if type.include?('Dataset')
        ROCrate::Directory
      else
        ROCrate::File
      end
    end

    ##
    # The payload of all the files/directories associated with this DataEntity, mapped by their relative file path.
    #
    # @return [Hash{String => Entry}>] The key is the location within the crate, and the value is an Entry.
    def payload
      {}
    end
    alias_method :entries, :payload

    ##
    # A disk-safe filepath based on the ID of this DataEntity.
    #
    # @return [String] The relative file path of this DataEntity within the Crate.
    def filepath
      Addressable::URI.unescape(id.sub(/\A\//, '')).to_s # Remove initial / and decode %20 etc.
    end
  end
end
