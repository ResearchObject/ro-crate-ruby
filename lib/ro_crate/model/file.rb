module ROCrate
  ##
  # A data entity that represents a single file.
  class File < DataEntity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    ##
    # Create a new ROCrate::File. PLEASE NOTE, the new file will not be added to the crate. To do this, call
    # Crate#add_data_entity, or just use Crate#add_file.
    #
    # @param crate [Crate] The RO crate that owns this file.
    # @param source [String, #read, nil] The source on the disk where this file will be read.
    # @param crate_path [String] The relative path within the RO crate where this file will be written.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this file.
    def initialize(crate, source, crate_path = nil, properties = {})
      source = Pathname.new(source).expand_path if source.is_a?(String) || source.is_a?(::File)
      crate_path = source.basename.to_s if crate_path.nil? && source.respond_to?(:basename)
      super(crate, crate_path, properties)
      @entry = Entry.new(source)
    end

    ##
    # The "physical" source file that will be read.
    #
    # @return [Entry] An Entry pointing to the source.
    def source
      @entry
    end

    ##
    # A map of all the files/directories associated with this File. Should only be a single key and value.
    # (for compatibility with Directory#entries)
    #
    # @return [Hash{String => Entry}>] The key is the location within the crate, and the value is an Entry.
    def entries
      { filepath => source }
    end

    private

    def default_properties
      super.merge(
        '@id' => "#{SecureRandom.uuid}",
        '@type' => 'File'
      )
    end
  end
end
