require 'rusen/settings'
require 'rusen/notifier'
require 'rusen/notification'

module Rusen
  module Middleware

    class RusenRack

      def initialize(app, settings = {})
        @app = app

        if settings.is_a?(::Rusen::Settings)
          @rusen_settings = settings
        else
          @rusen_settings = Settings.new

          @rusen_settings.outputs = settings[:outputs]
          @rusen_settings.sections = settings[:sections]
          @rusen_settings.filter_parameters = settings[:filter_parameters]
          @rusen_settings.email_prefix = settings[:email_prefix]
          @rusen_settings.sender_address = settings[:sender_address]
          @rusen_settings.exception_recipients = settings[:exception_recipients]
          @rusen_settings.smtp_settings = settings[:smtp_settings]
          @rusen_settings.exclude_if = settings[:exclude_if]
        end

        @notifier = Notifier.new(@rusen_settings)
      end

      def call(env)
        begin
          @app.call(env)
        rescue Exception => error
          unless @rusen_settings.exclude_if.call(error)
            request = Rack::Request.new(env)
            @notifier.notify(error, request.GET.merge(request.POST), env, request.session)
          end

          raise
        end
      end

    end

  end
end
