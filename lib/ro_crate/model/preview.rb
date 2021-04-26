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

    def initialize(crate, source = nil, properties = {})
      source ||= PreviewGenerator.new(self)
      @template = nil
      super(crate, source, IDENTIFIER, properties)
    end

    private

    def default_properties
      {
        '@id' => IDENTIFIER,
        '@type' => 'CreativeWork',
        'about' => { '@id' => ROCrate::Crate::IDENTIFIER }
      }
    end
  end
end
