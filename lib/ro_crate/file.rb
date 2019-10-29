module ROCrate
  class File < Entity
    include Writeable

    attr_accessor :content
    properties(%w[name contentSize dateModified fileFormat encodingFormat givenName identifier sameAs])

    def initialize(crate, content, path = nil)
      @content = content
      super(crate, path)
    end

    private

    def default_properties
      super.merge('@type' => 'File')
    end
  end
end
