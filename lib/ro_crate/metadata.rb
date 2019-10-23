module ROCrate
  class Metadata
    def initialize(ro_crate)
      @ro_crate = ro_crate
    end

    def write(io)
      graph = []
      graph << metadata_metadata
      graph << crate_metadata
      @ro_crate.entries.each do |entry|
        graph << entry_metadata(entry)
      end

      compacted = { '@context' => context, '@graph' => graph }

      io.write(JSON.pretty_generate(compacted))
    end

    private

    def context
      'https://w3id.org/ro/crate/0.2/context'
    end

    def crate_metadata
      {
          "@id" => "./",
          "@type" => "Dataset",
          "hasPart" => @ro_crate.entries.map { |entry| { '@id' => entry.id } }
      }
    end

    def metadata_metadata
      {
          "@type" => "CreativeWork",
          "@id" => "ro-crate-metadata.jsonld",
          "identifier" => "ro-crate-metadata.jsonld",
          "about" => {"@id" => "./"}
      }
    end

    def entry_metadata(entry)
      {
          "@id" => entry.id,
          "@type" => "File",
          "contentSize" => "#{entry.content_size}",
          "description" => "#{entry.description}",
          "encodingFormat" => 'text/plain'
      }
    end
  end
end
