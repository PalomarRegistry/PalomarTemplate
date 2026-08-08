# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"

require_relative "../scripts/validate-formalization"

class ValidateFormalizationTest < Minitest::Test
  def metadata(text)
    Tempfile.create(["formalization", ".yaml"]) do |file|
      file.write(text)
      file.flush
      return yield file.path
    end
  end

  def test_accepts_customized_yaml
    metadata(<<~YAML) do |path|
      project:
        name: Example
      classification:
        arxiv: [math.LO]
        msc2020: [03B35]
      status:
        sorry_count: 0
    YAML
      assert_nil FormalizationTemplate.validate(path)
    end
  end

  def test_reports_every_nested_template_value
    metadata(<<~YAML) do |path|
      project:
        name: "TEMPLATE: project name"
      classification:
        arxiv: ["TEMPLATE: arXiv category"]
      status:
        scope: >-
          TEMPLATE: describe the proved scope
    YAML
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "3 TEMPLATE value(s)"
      assert_includes error.message, "$.project.name"
      assert_includes error.message, "$.classification.arxiv[0]"
      assert_includes error.message, "$.status.scope"
    end
  end

  def test_requires_a_yaml_mapping
    metadata("- not\n- a\n- mapping\n") do |path|
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "one top-level mapping"
    end
  end

  def test_rejects_invalid_yaml
    metadata("project: [unterminated\n") do |path|
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "cannot read"
    end
  end
end
