module ROCrate
  ##
  # A class to represent a "Data Entity" within an RO-Crate.
  # Data Entities are the actual physical files and directories within the Crate.
  class DataEntity < Entity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs author])

    ##
    # Return an appropriate specialization of DataEntity for the given properties.
    # @param props [Hash] Set of properties to try and infer the type from.
    # @return [Class]
    def self.specialize(props)
      type = props['@type']
      type = [type] unless type.is_a?(Array)
      if type.include?('Dataset')
        ROCrate::Directory
      elsif type.include?('File')
        ROCrate::File
      else
        self
      end
    end

    ##
    # Create a new ROCrate::DataEntity. This entity represents something that is neither a file or directory, but
    # still constitutes part of the crate.
    # PLEASE NOTE, the new data entity will not be added to the crate. To do this, call Crate#add_data_entity.
    #
    # @param crate [Crate] The RO-Crate that owns this directory.
    # @param source [nil] Ignored. For compatibility with the File and Directory constructor signatures.
    # @param id [String, nil] An ID to identify this DataEntity, or nil to auto-generate an appropriate one,
    #   (or determine via the properties param)
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this DataEntity.
    def initialize(crate, source = nil, id = nil, properties = {})
      super(crate, id, properties)
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
