module ROCrate
  class JSONLDHash < ::Hash
    def initialize(graph, content = {})
      @graph = graph
      super()
      update(content)
    end

    def [](key)
      val = super
      if val.instance_of?(::Hash)
        self.class.new(@graph, val)
      else
        val
      end
    end

    def dereference
      @graph.dereference(self['@id']) if self['@id']
    end
  end
end
