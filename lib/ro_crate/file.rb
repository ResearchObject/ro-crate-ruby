module ROCrate
  class File < Entity
    attr_accessor :content

    properties(%w[name contentSize dateModified fileFormat encodingFormat givenName identifier sameAs])

    def initialize(crate, content, path = nil)
      @content = content
      path = "./#{path}" if path && !path.start_with?('./') # TODO: Find a better way of doing this...
      super(crate, path)
    end

    def filename
      filepath.split(File::SEPARATOR).last
    end

    def filepath
      id.sub(/\A.\//, '')
    end

    def write(io)
      io.write(content.respond_to?(:read) ? content.read : content)
    end

    private

    def default_properties
      super.merge('@type' => 'File')
    end
  end
end
