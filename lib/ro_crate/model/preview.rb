require 'erb'

module ROCrate
  ##
  # A representation of the `ro-crate-preview.html` file.
  class Preview < File
    IDENTIFIER = 'ro-crate-preview.html'.freeze
    DEFAULT_TEMPLATE = ::File.expand_path(::File.join(::File.dirname(__FILE__), '..', 'ro-crate-preview.html.erb'))

    ##
    # The ERB template to use when rendering the preview.
    # @return [String]
    attr_accessor :template

    def initialize(crate, properties = {})
      @template = nil
      super(crate, nil, IDENTIFIER, properties)
    end

    ##
    # Generate the crate's `ro-crate-preview.html`.
    # @return [String] The rendered HTML as a string.
    def generate
      b = crate.get_binding
      renderer = ERB.new(template || ::File.read(DEFAULT_TEMPLATE))
      renderer.result(b)
    end

    private

    def source
      Entry.new(StringIO.new(generate))
    end

    def default_properties
      {
        '@id' => IDENTIFIER,
        '@type' => 'CreativeWork',
        'about' => { '@id' => ROCrate::Crate::IDENTIFIER }
      }
    end
  end
end
