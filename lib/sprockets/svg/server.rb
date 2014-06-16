require 'tempfile'
require 'pathname'

module Sprockets
  module Svg
    module Server

      def self.included(base)
        base.send(:alias_method, :find_asset_without_conversion, :find_asset)
        base.send(:alias_method, :find_asset, :find_asset_with_conversion)
      end

      def find_asset_with_conversion(path, options = {})
        convert = false
        if path.to_s.ends_with?('.svg.png')
          path = path.gsub(/\.png/, '')
          convert = true
        end
        asset = find_asset_without_conversion(path, options)

        if asset && convert
          asset = svg_asset_to_static_png(asset)
        end

        asset
      end

      def svg2png_cache_path
        @cache_path ||= cache.instance_variable_get(:@root).join('svg2png')
      end

      def svg_asset_to_static_png(svg_asset)
        tmp_path = Tempfile.new(['svg2png', '.svg']).path
        svg_asset.write_to(tmp_path)
        png_asset = ::Sprockets::StaticAsset.new(self, svg_asset.logical_path + '.png', Pathname.new(tmp_path + '.png'))
        png_asset.instance_variable_set(:@digest, svg_asset.digest)
        png_asset
      end

      def each_file(*args)
        return to_enum(__method__) unless block_given?

        super do |path|
          yield path
          if Svg.image?(path.to_s)
            yield Pathname.new(path.to_s + '.png')
          end
        end
      end

    end
  end
end
