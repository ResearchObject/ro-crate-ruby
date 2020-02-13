module ROCrate
  class File < Entity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def self.format_id(id)
      super.chomp('/')
    end

    def initialize(crate, path_or_io, crate_path = nil, properties = {})
      super(crate, crate_path, properties)
      @io = path_or_io
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
    # Write the file to the given IO destination.
    def write(dest)
      source = content
      if source.respond_to?(:read)
        source = source.open('rb') if source.is_a?(Pathname)
        while buff = source.read(4096)
          dest.write(buff)
        end
      else
        dest.write(source)
      end
    end

    def directory?
      false
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
