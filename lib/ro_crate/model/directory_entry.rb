module ROCrate
  class Directory < Entity
    attr_accessor :content
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def initialize(crate, dir, path = nil, properties = {})
      @dir = dir
      super(crate, path, properties)
    end

    def entries
      Dir.glob("#{dir}/**/*").map do |path|
        DirectoryEntry.new(path)
      end
    end

    private

    def default_properties
      super.merge(
        '@id' => "./#{SecureRandom.uuid}/",
        '@type' => 'Dataset'
      )
    end
  end
end
