#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

module FormalizationTemplate
  SENTINEL = /\ATEMPLATE(?::|\z)/

  class ValidationError < StandardError; end

  def self.placeholder_paths(value, path = "$")
    case value
    when Hash
      value.flat_map do |key, child|
        placeholder_paths(child, "#{path}.#{key}")
      end
    when Array
      value.each_with_index.flat_map do |child, index|
        placeholder_paths(child, "#{path}[#{index}]")
      end
    when String
      value.lstrip.match?(SENTINEL) ? [path] : []
    else
      []
    end
  end

  def self.validate(path)
    document = YAML.safe_load(
      File.read(path, encoding: "UTF-8"),
      permitted_classes: [],
      permitted_symbols: [],
      aliases: false
    )
    raise ValidationError, "#{path} must contain one top-level mapping" unless document.is_a?(Hash)

    placeholders = placeholder_paths(document)
    return if placeholders.empty?

    locations = placeholders.map { |item| "  #{item}" }.join("\n")
    raise ValidationError, <<~MESSAGE.chomp
      #{path} still contains #{placeholders.length} TEMPLATE value(s):
      #{locations}
      Replace every listed value with project-specific metadata; use [] for a placeholder list where the honest answer is none.
    MESSAGE
  rescue Errno::ENOENT, EncodingError, Psych::Exception => error
    raise ValidationError, "cannot read #{path} as YAML: #{error.message.lines.first&.strip}"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    path = ARGV.fetch(0, "formalization.yaml")
    FormalizationTemplate.validate(path)
    puts "#{path} contains no TEMPLATE values"
  rescue FormalizationTemplate::ValidationError => error
    warn error.message
    exit 1
  end
end
