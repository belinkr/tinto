# encoding: utf-8
$:.unshift File.expand_path('../../../Lib', __FILE__)
require 'ostruct'
require 'minitest/autorun'
require_relative '../../Lib/Tinto/Localizer'

describe Tinto::Localizer do
  before do
    @fake_app_class = Class.new {
      attr_accessor :session, :params, :request

      def initialize(options={})
        @session = { locale: options[:session] }
        @params  = { locale: options[:param]   }
        @request = OpenStruct.new(
          env: { 'HTTP_ACCEPT_LANGUAGE' => options[:browser] }
        )
      end
    }
  end
  
  describe '#profile_locale' do
    it 'gets locale from the passed user profile object' do
      app     = @fake_app_class.new
      profile = OpenStruct.new(locale: 'es')
      Tinto::Localizer.new(app, profile).profile_locale.must_equal :es
    end
  end

  describe '#session_locale' do
    it 'gets locale from the session' do
      app = @fake_app_class.new(session: 'es')
      Tinto::Localizer.new(app).session_locale.must_equal :'es'
    end

    it 'returns false if session has no locale' do
      app = @fake_app_class.new
      Tinto::Localizer.new(app).session_locale.must_equal false
    end
  end

  describe '#browser_locale' do
    it 'gets the locale from the ACCEPT_LANGUAGE HTTP header' do
      app = @fake_app_class.new(browser: 'zh_CN')
      Tinto::Localizer.new(app).browser_locale.must_equal :'zh_CN'

      app = @fake_app_class.new(browser: 'zh_CN')
      Tinto::Localizer.new(app).browser_locale.must_equal :'zh_CN'
    end

    it 'returns false if no ACCEPT_LANGUAGE HTTP header provided' do
      app = @fake_app_class.new(browser: '')
      Tinto::Localizer.new(app).browser_locale.must_equal false

      app = @fake_app_class.new(browser: nil)
      Tinto::Localizer.new(app).browser_locale.must_equal false
    end
  end

  describe '#locale_param' do
    it 'gets the locale from the ACCEPT_LANGUAGE HTTP header' do
      app = @fake_app_class.new(param: :en)
      Tinto::Localizer.new(app).locale_param.must_equal :en

      app = @fake_app_class.new(param: 'es_ES')
      Tinto::Localizer.new(app).locale_param.must_equal :'es_ES'
    end

    it 'returns false if no :locale param provided' do
      app = @fake_app_class.new(param: '')
      Tinto::Localizer.new(app).locale_param.must_equal false

      app = @fake_app_class.new
      Tinto::Localizer.new(app).locale_param.must_equal false
    end
  end

  describe '#can_handle?' do
    it 'returns true if I18n class can handle the locale' do
      I18n.available_locales = [:en]
      app = @fake_app_class.new
      Tinto::Localizer.new(app).can_handle?(:en).must_equal true
    end

    it 'returns false if I18n class is not aware of that locale' do
      I18n.available_locales = [:en]
      app = @fake_app_class.new
      Tinto::Localizer.new(app).can_handle?(:de).must_equal false
    end
  end

  describe '#locale' do
    it 'selects locale with this preference: param, session, profile, HTTP header
      and removes the country suffix, if any' do
      I18n.available_locales = [:en, :fr, :de, :zh]
      app = @fake_app_class.new(param: :de, session: nil, browser: 'zh_CN')
      Tinto::Localizer.new(app).locale.must_equal :de

      app = @fake_app_class.new(param: :de, session: nil, browser: 'zh_CN')
      profile = OpenStruct.new(locale: 'fr')
      Tinto::Localizer.new(app, profile).locale.must_equal :de

      app = @fake_app_class.new(param: :nil, session: nil, browser: 'zh_CN')
      profile = OpenStruct.new(locale: 'fr')
      Tinto::Localizer.new(app, profile).locale.must_equal :fr

      app = @fake_app_class.new(param: :nil, session: :de, browser: 'zh_CN')
      profile = OpenStruct.new(locale: 'fr')
      Tinto::Localizer.new(app, profile).locale.must_equal :de

      app = @fake_app_class.new(param: nil, session: :fr, browser: 'zh_CN')
      Tinto::Localizer.new(app).locale.must_equal :fr

      app = @fake_app_class.new(param: nil, session: nil, browser: 'zh_CN')
      Tinto::Localizer.new(app).locale.must_equal :zh
    end

    it 'makes sure selected locale is available, otherwise selects alternatives
    in preferred order, using default as a fallback' do
      I18n.available_locales = [:en, :zh]

      app = @fake_app_class.new(param: 'de', session: nil, browser: 'zh_CN')
      Tinto::Localizer.new(app).locale.must_equal :zh

      app = @fake_app_class.new(param: 'de', session: nil, browser: nil)
      Tinto::Localizer.new(app).locale.must_equal :en
    end
  end # locale
end # Tinto::Localizer
