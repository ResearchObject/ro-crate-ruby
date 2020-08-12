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
    # @param source [String, Pathname, ::File, #read, URI, nil] The source on the disk (or on the internet if a URI) where this file will be read.
    # @param crate_path [String] The relative path within the RO crate where this file will be written.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this file.
    def initialize(crate, source, crate_path = nil, properties = {})
      if crate_path.is_a?(Hash) && properties.empty?
        properties = crate_path
        crate_path = nil
      end

      if source.is_a?(String)
        uri = URI(source) rescue nil
        if uri.absolute?
          source = uri
        else
          source = Pathname.new(source).expand_path
        end
      elsif source.is_a?(::File)
        source = Pathname.new(source).expand_path
      end

      if crate_path.nil?
        crate_path = source.basename.to_s if source.respond_to?(:basename)
        crate_path = source.to_s if source.is_a?(URI) && source.absolute?
      end

      super(crate, crate_path, properties)

      if source.is_a?(URI) && source.absolute?
        @entry = RemoteEntry.new(source)
      else
        @entry = Entry.new(source)
      end
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
      remote? ? {} : { filepath => source }
    end

    def remote?
      @entry.remote?
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
