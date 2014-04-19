require_relative "../../../base"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/providers/docker/config")

describe VagrantPlugins::DockerProvider::Config do
  include_context "unit"

  let(:machine) { double("machine") }

  let(:build_dir) do
    temporary_dir.tap do |dir|
      dir.join("Dockerfile").open("w") do |f|
        f.write("Hello")
      end
    end
  end

  def assert_invalid
    errors = subject.validate(machine)
    if !errors.values.any? { |v| !v.empty? }
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.values.all? { |v| v.empty? }
      raise "Errors: #{errors.inspect}"
    end
  end

  def valid_defaults
    subject.image = "foo"
  end

  describe "defaults" do
    before { subject.finalize! }

    its(:build_dir) { should be_nil }
    its(:cmd) { should eq([]) }
    its(:env) { should eq({}) }
    its(:force_host_vm) { should be_false }
    its(:image) { should be_nil }
    its(:name) { should be_nil }
    its(:privileged) { should be_false }
    its(:vagrant_machine) { should be_nil }
    its(:vagrant_vagrantfile) { should be_nil }
  end

  before do
    # By default lets be Linux for validations
    Vagrant::Util::Platform.stub(linux: true)
  end

  it "should be invalid if both build dir and image are set" do
    subject.build_dir = build_dir
    subject.image = "foo"
    subject.finalize!
    assert_invalid
  end

  describe "#build_dir" do
    it "should be valid if not set with image" do
      subject.build_dir = nil
      subject.image = "foo"
      subject.finalize!
      assert_valid
    end

    it "should be valid with a valid directory" do
      subject.build_dir = build_dir
      subject.finalize!
      assert_valid
    end

    it "should be invalid with a directory that doesn't have a Dockerfile" do
      subject.build_dir = temporary_dir.to_s
      subject.finalize!
      assert_invalid
    end
  end

  describe "#image" do
    it "should be valid if set" do
      subject.image = "foo"
      subject.finalize!
      assert_valid
    end

    it "should be invalid if not set" do
      subject.image = nil
      subject.finalize!
      assert_invalid
    end
  end

  describe "#link" do
    before do
      valid_defaults
    end

    it "should be valid with good links" do
      subject.link "foo:bar"
      subject.link "db:blah"
      subject.finalize!
      assert_valid
    end

    it "should be invalid if not name:alias" do
      subject.link "foo"
      subject.finalize!
      assert_invalid
    end

    it "should be invalid if too many colons" do
      subject.link "foo:bar:baz"
      subject.finalize!
      assert_invalid
    end
  end

  describe "#merge" do
    let(:one) { described_class.new }
    let(:two) { described_class.new }

    subject { one.merge(two) }

    context "env vars" do
      it "should merge the values" do
        one.env["foo"] = "bar"
        two.env["bar"] = "baz"

        expect(subject.env).to eq({
          "foo" => "bar",
          "bar" => "baz",
        })
      end
    end

    context "links" do
      it "should merge the links" do
        one.link "foo"
        two.link "bar"

        expect(subject._links).to eq([
          "foo", "bar"])
      end
    end
  end

  describe "#vagrant_vagrantfile" do
    before { valid_defaults }

    it "should be valid if set to a file" do
      subject.vagrant_vagrantfile = temporary_file.to_s
      subject.finalize!
      assert_valid
    end

    it "should not be valid if set to a non-existent place" do
      subject.vagrant_vagrantfile = "/i/shouldnt/exist"
      subject.finalize!
      assert_invalid
    end
  end
end
