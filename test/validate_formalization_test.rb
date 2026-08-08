# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "pathname"
require "rbconfig"
require "tempfile"

require_relative "../scripts/validate-formalization"

class ValidateFormalizationTest < Minitest::Test
  ROOT = Pathname(__dir__).parent
  SCRIPT = ROOT / "scripts/validate-formalization.rb"
  SHIPPED_METADATA = ROOT / "formalization.yaml"
  SHIPPED_TEMPLATE_PATHS = [
    "$.project.name",
    "$.project.authors[0]",
    "$.project.responsible_maintainers[0]",
    "$.repository.role",
    "$.classification.arxiv[0]",
    "$.classification.msc2020[0]",
    "$.sources[0].title",
    "$.sources[0].authors[0]",
    "$.sources[0].id",
    "$.sources[0].type",
    "$.sources[0].location",
    "$.sources[0].relationship",
    "$.sources[0].license",
    "$.sources[0].author_endorsement",
    "$.related_formalizations[0].id",
    "$.related_formalizations[0].relationship",
    "$.related_formalizations[0].note",
    "$.status.scope",
    "$.status.sorry_count",
    "$.status.sorry_in_definitions",
    "$.status.axioms[0]",
    "$.status.main_results[0].declaration",
    "$.status.main_results[0].file",
    "$.status.main_results[0].sorry_count",
    "$.status.main_results[0].axioms[0]",
    "$.status.main_results[0].comparator_config",
    "$.status.main_results[0].literature_dependencies[0]",
    "$.automation.methods[0].method",
    "$.automation.methods[0].models[0]",
    "$.automation.methods[0].framework",
    "$.automation.methods[0].tool_setup",
    "$.automation.methods[0].cost.wall_time",
    "$.automation.methods[0].cost.spend_usd",
    "$.automation.methods[0].cost.hardware",
    "$.automation.methods[0].prompting_notes",
    "$.automation.spend_usd",
    "$.automation.notes",
    "$.fidelity.divergences",
    "$.review.status",
    "$.review.reviewers[0]",
    "$.review.notes",
    "$.alignment.namespace",
    "$.alignment.statements[0].source",
    "$.alignment.statements[0].lean",
    "$.alignment.statements[0].module",
    "$.alignment.statements[0].status",
    "$.alignment.statements[0].note",
    "$.acknowledgements"
  ].freeze

  CUSTOMIZED_YAML = <<~YAML
    project:
      name: Example
    classification:
      arxiv: [math.LO]
      msc2020: [03B35]
    automation:
      methods:
        - method: manual
    review:
      status: self-assessed
  YAML

  def metadata(contents)
    Tempfile.create(["formalization", ".yaml"]) do |file|
      file.binmode
      file.write(contents)
      file.flush
      return yield file.path
    end
  end

  def cli(*arguments)
    Open3.capture3(RbConfig.ruby, SCRIPT.to_s, *arguments)
  end

  def test_shipped_metadata_is_valid_and_has_the_exact_template_surface
    document = FormalizationTemplate.load_document(SHIPPED_METADATA)
    assert_equal SHIPPED_TEMPLATE_PATHS, FormalizationTemplate.placeholder_paths(document)
    assert_equal SHIPPED_TEMPLATE_PATHS,
                 FormalizationTemplate.validate(SHIPPED_METADATA, expect_template: true)
  end

  def test_accepts_customized_yaml
    metadata(CUSTOMIZED_YAML) do |path|
      assert_empty FormalizationTemplate.validate(path)
    end
  end

  def test_reports_placeholders_inside_arrays_of_mappings
    document = {
      "sources" => [
        {"authors" => [{"name" => "TEMPLATE: source author"}]}
      ]
    }
    assert_equal ["$.sources[0].authors[0].name"],
                 FormalizationTemplate.placeholder_paths(document)
  end

  def test_sentinel_is_anchored_and_accepts_bare_or_colon_forms
    document = {
      "values" => [
        "TEMPLATE",
        "TEMPLATE: replace me",
        "  TEMPLATE: replace me too",
        "TEMPLATES are useful",
        "prefix TEMPLATE: is ordinary text",
        "template: is case-sensitive"
      ]
    }
    assert_equal ["$.values[0]", "$.values[1]", "$.values[2]"],
                 FormalizationTemplate.placeholder_paths(document)
  end

  def test_requires_a_yaml_mapping
    metadata("- not\n- a\n- mapping\n") do |path|
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "one top-level mapping"
    end
  end

  def test_requires_all_metadata_sections
    metadata("project: {}\nclassification: {}\n") do |path|
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "required mapping sections: automation, review"
    end
  end

  def test_rejects_invalid_yaml
    metadata("project: [unterminated\n") do |path|
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "cannot parse"
    end
  end

  def test_rejects_invalid_utf8_before_parsing
    metadata("project: \xFF\n".b) do |path|
      error = assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.validate(path)
      end
      assert_includes error.message, "must be valid UTF-8"
    end
  end

  def test_wraps_system_call_errors
    error = File.stub(:binread, ->(_path) { raise Errno::EACCES, "denied" }) do
      assert_raises(FormalizationTemplate::ValidationError) do
        FormalizationTemplate.load_document("unreadable.yaml")
      end
    end
    assert_includes error.message, "cannot read unreadable.yaml"
  end

  def test_derived_cli_succeeds_only_without_sentinels
    metadata(CUSTOMIZED_YAML) do |path|
      output, errors, status = cli(path)
      assert_predicate status, :success?
      assert_equal "#{path} contains no TEMPLATE values\n", output
      assert_empty errors
    end

    metadata(CUSTOMIZED_YAML.sub("Example", '"TEMPLATE: project name"')) do |path|
      output, errors, status = cli(path)
      refute_predicate status, :success?
      assert_equal 1, status.exitstatus
      assert_empty output
      assert_includes errors, "still contains 1 TEMPLATE value(s)"
      assert_includes errors, "$.project.name"
    end
  end

  def test_template_cli_succeeds_only_for_the_shipped_surface
    output, errors, status = cli("--expect-template", SHIPPED_METADATA.to_s)
    assert_predicate status, :success?
    assert_equal "#{SHIPPED_METADATA} contains the expected 48 TEMPLATE values\n", output
    assert_empty errors

    metadata(CUSTOMIZED_YAML) do |path|
      output, errors, status = cli("--expect-template", path)
      refute_predicate status, :success?
      assert_equal 1, status.exitstatus
      assert_empty output
      assert_includes errors, "does not have the expected TEMPLATE sentinel surface"
      assert_includes errors, "missing expected values: $.project.name"
    end

    metadata("project: [unterminated\n") do |path|
      output, errors, status = cli("--expect-template", path)
      refute_predicate status, :success?
      assert_equal 1, status.exitstatus
      assert_empty output
      assert_includes errors, "cannot parse #{path} as YAML"
    end
  end

  def test_cli_reports_usage_errors_separately
    output, errors, status = cli("--not-an-option")
    refute_predicate status, :success?
    assert_equal 2, status.exitstatus
    assert_empty output
    assert_includes errors, "invalid option: --not-an-option"
    assert_includes errors, "Usage:"
  end
end

class MetadataWorkflowRoutingTest < Minitest::Test
  WORKFLOW = File.read(Pathname(__dir__).parent / ".github/workflows/ci.yml")

  def test_only_the_canonical_repository_and_its_direct_forks_use_template_mode
    assert_includes WORKFLOW, <<~YAML.chomp
      if: github.repository == 'PalomarRegistry/PalomarTemplate' || github.event.repository.parent.full_name == 'PalomarRegistry/PalomarTemplate'
    YAML
    assert_includes WORKFLOW, <<~YAML.chomp
      if: github.repository != 'PalomarRegistry/PalomarTemplate' && github.event.repository.parent.full_name != 'PalomarRegistry/PalomarTemplate'
    YAML
    refute_includes WORKFLOW, "github.event.repository.fork"
  end
end
