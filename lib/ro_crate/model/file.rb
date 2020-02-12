module ROCrate
  class File < Entity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def initialize(crate, io, path = nil, properties = {})
      @io = io
      super(crate, path, properties)
    end

    def content
      @io
    end

    ##
    # The path of the file, relative to the root of the RO crate.
    def filepath
      Addressable::URI.unescape(canonical_id.path.sub(/\A\//, '')) # Remove initial / and decode %20 etc.
    end

    ##
    # Write the file to the given IO.
    def write(io)
      io.write(content.respond_to?(:read) ? content.read : content)
    end

    def directory?
      false
    end

    private

    def default_properties
      super.merge(
        '@id' => "./#{SecureRandom.uuid}",
        '@type' => 'File'
      )
    end
  end
end
