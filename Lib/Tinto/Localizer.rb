# encoding: utf-8
require 'i18n'

module Tinto
  class Localizer
    attr_accessor :app, :profile

    DefaultLocale     = :en
    AcceptLanguageRE  = %r{.*[a-zA-Z]{2}[_-][a-zA-Z].*}

    def initialize(app, profile=nil)
      @app      = app
      @profile  = profile
    end

    def profile_locale
      if profile && profile.respond_to?(:locale)
        profile.locale.to_sym
      else
        false
      end
    end

    def session_locale
      app.session[:locale] ? app.session[:locale].to_sym : false
    end

    def browser_locale
      accept_language = app.request.env['HTTP_ACCEPT_LANGUAGE'] || ''
      matchdata       = accept_language.match(AcceptLanguageRE) || []
      matchdata[0] ? matchdata[0].to_sym : false
    end

    def locale_param
      locale = app.params[:locale] 
      (locale && !locale.empty?) ? locale.to_sym : false
    end

    def locale
      sources = [ 
        locale_param, session_locale, profile_locale, 
        browser_locale, DefaultLocale
      ].map { |source| remove_country_suffix_from(source) }
      sources.keep_if { |locale| can_handle?(locale) }.first
    end

    def can_handle?(locale)
      locale ? I18n.available_locales.include?(locale.to_sym) : false
    end

    private

    def remove_country_suffix_from(locale)
      locale.to_s.split("_").first.to_sym
    end
  end # Localizer
end # Tinto
