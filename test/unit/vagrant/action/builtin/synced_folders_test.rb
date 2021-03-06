require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::SyncedFolders do
  include_context "unit"
  include_context "synced folder actions"

  let(:app) { lambda { |env| } }
  let(:env) { { :machine => machine, :ui => ui } }
  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:config).and_return(machine_config)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      top_config.stub(:vm => vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config") }

  let(:ui) do
    double("ui").tap do |result|
      allow(result).to receive(:info)
    end
  end

  subject { described_class.new(app, env) }

  describe "call" do
    let(:synced_folders) { {} }
    let(:plugins) { {} }

    before do
      plugins[:default] = [impl(true, "default"), 10]
      plugins[:nfs] = [impl(true, "nfs"), 5]

      env[:root_path] = Pathname.new(Dir.mktmpdir)
      subject.stub(:plugins => plugins)
      subject.stub(:synced_folders => synced_folders)
    end

    it "should create on the host if specified" do
      synced_folders["default"] = {
        "root" => {
          hostpath: "foo",
        },

        "other" => {
          hostpath: "bar",
          create: true,
        }
      }

      subject.call(env)

      expect(env[:root_path].join("foo")).not_to be_directory
      expect(env[:root_path].join("bar")).to be_directory
    end

    it "should invoke prepare then enable" do
      ids   = []
      order = []
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          ids   << self.object_id
          order << :prepare
        end

        define_method(:enable) do |machine, folders, opts|
          ids   << self.object_id
          order << :enable
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
        },

        "other" => {
          hostpath: "bar",
          create: true,
        }
      }

      subject.call(env)

      expect(order).to eq([:prepare, :enable])
      expect(ids.length).to eq(2)
      expect(ids[0]).to eq(ids[1])
    end
  end
end
