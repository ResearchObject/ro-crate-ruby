module ROCrate
  ##
  # A data entity that represents a single file.
  class File < DataEntity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def initialize(crate, source, crate_path = nil, properties = {})
      super(crate, crate_path, properties)
      @source = Entry.new(source)
    end

    def source
      @source
    end

    ##
    # A map of all the files/directories associated with this DataEntity. For files, it will contain a single key/value.
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
