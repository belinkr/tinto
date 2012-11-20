# encoding: utf-8
require 'i18n'
require 'aequitas'

module Tinto   
  class Transformer < Aequitas::MessageTransformer
    NAMESPACE = "validation.errors"

    def self.transform(violation)
      raise ArgumentError, "+violation+ must be specified" if violation.nil?
      resource       = violation.resource
      model_name     = resource.class.const_get "MODEL_NAME"
      attribute_name = violation.attribute_name

      options = {
        model:      ::I18n.translate("models.#{model_name}"),
        attribute:  ::I18n.translate(
                        "#{model_name}.attributes.#{attribute_name}"
                      ),
        value:      resource.validation_attribute_value(attribute_name),
      }.merge(violation.info)

      ::I18n.translate("#{NAMESPACE}.#{violation.type}", options)
    end
  end # Transformer
end # Tinto

Aequitas::Violation.default_transformer = Tinto::Transformer
