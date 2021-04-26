require 'erb'

module ROCrate
  ##
  # A class to handle generation of an RO-Crate's preview HTML in an IO-like way (to fit into an Entry).
  class PreviewGenerator
    ##
    # @param preview [Preview] The RO-Crate preview object.
    def initialize(preview)
      @preview = preview
    end

    def read(*args)
      io.read(*args)
    end

    ##
    # Generate the crate's `ro-crate-preview.html`.
    # @return [String] The rendered HTML as a string.
    def generate
      b = crate.get_binding
      renderer = ERB.new(template)
      renderer.result(b)
    end

    def template
      @preview.template || ::File.read(Preview::DEFAULT_TEMPLATE)
    end

    def crate
      @preview.crate
    end

    private

    def io
      @io ||= StringIO.new(generate)
    end
  end
end
