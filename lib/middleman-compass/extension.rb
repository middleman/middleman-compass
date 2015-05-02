require 'middleman-core/renderers/sass'

module Middleman
  class CompassExtension < Extension
    # Expose the `compass_config` method inside config.
    expose_to_config :compass_config

    def initialize(app, options_hash={}, &block)
      require 'compass'
      @compass_config_callbacks = []

      super
    end

    def compass_config(&block)
      @compass_config_callbacks << block
    end

    def execute_compass_config_callbacks(config)
      @compass_config_callbacks.each do |b|
        instance_exec(config, &b)
      end
    end

    def after_configuration
      ::Compass.configuration do |compass|
        compass.project_path    = app.config[:source]
        compass.environment     = :development
        compass.cache           = false
        compass.sass_dir        = app.config[:css_dir]
        compass.css_dir         = app.config[:css_dir]
        compass.javascripts_dir = app.config[:js_dir]
        compass.fonts_dir       = app.config[:fonts_dir]
        compass.images_dir      = app.config[:images_dir]
        compass.http_path       = app.config[:http_prefix]

        # Disable this initially, the cache_buster extension will
        # re-enable it if requested.
        compass.asset_cache_buster { |_| nil }

        # Disable this initially, the relative_assets extension will

        compass.relative_assets = false

        # Default output style
        compass.output_style = :nested
      end

      # Call hook
      execute_compass_config_callbacks(::Compass.configuration)

      # Tell Tilt to use it as well (for inline sass blocks)
      ::Tilt.register 'sass', CompassSassTemplate
      ::Tilt.prefer(CompassSassTemplate)

      # Tell Tilt to use it as well (for inline scss blocks)
      ::Tilt.register 'scss', CompassScssTemplate
      ::Tilt.prefer(CompassScssTemplate)
    end

    # A Compass Sass template for Tilt, adding our options in
    class CompassSassTemplate < ::Middleman::Renderers::Sass::SassPlusCSSFilenameTemplate
      def sass_options
        super.merge(::Compass.configuration.to_sass_engine_options)
      end
    end

    # A Compass Scss template for Tilt, adding our options in
    class CompassScssTemplate < ::Middleman::Renderers::Sass::ScssPlusCSSFilenameTemplate
      def sass_options
        super.merge(::Compass.configuration.to_sass_engine_options)
      end
    end
  end
end