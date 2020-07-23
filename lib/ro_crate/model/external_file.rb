module ROCrate
  ##
  # A data entity that represents a single file that is held elsewhere.
  class ExternalFile < DataEntity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def self.format_id(id)
      raise "Must be an absolute URI!" unless URI(id).absolute?
      id
    end

    ##
    # Create a new ROCrate::ExternalFile. PLEASE NOTE, the new file will not be added to the crate. To do this, call
    # Crate#add_data_entity, or just use Crate#add_file.
    #
    # @param crate [Crate] The RO crate that owns this file.
    # @param uri [String, URI] The URI of the file.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this file.
    def initialize(crate, uri, properties = {})
      super(crate, uri.to_s, properties)
    end

    ##
    # Open the remote URI.
    #
    # @return [IO] An IO object.
    def source
      open(id)
    end

    private

    def default_properties
      super.merge(
        '@type' => 'File'
      )
    end
  end
end
