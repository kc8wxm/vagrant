module VagrantPlugins
  module DockerProvider
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :image, :cmd, :ports, :volumes, :privileged

      # The directory with a Dockerfile to build and use as the basis
      # for this container. If this is set, "image" should not be set.
      #
      # @return [String]
      attr_accessor :build_dir

      # Additional arguments to pass to `docker run` when creating
      # the container for the first time. This is an array of args.
      #
      # @return [Array<String>]
      attr_accessor :create_args

      # Environmental variables to set in the container.
      #
      # @return [Hash]
      attr_accessor :env

      # True if the Docker container exposes SSH access. If this is true,
      # then Vagrant can do a bunch more things like setting the hostname,
      # provisioning, etc.
      attr_accessor :has_ssh

      # The name for the container. This must be unique for all containers
      # on the proxy machine if it is made.
      #
      # @return [String]
      attr_accessor :name

      # True if the docker container is meant to stay in the "running"
      # state (is a long running process). By default this is true.
      #
      # @return [Boolean]
      attr_accessor :remains_running

      # The name of the machine in the Vagrantfile set with
      # "vagrant_vagrantfile" that will be the docker host. Defaults
      # to "default"
      #
      # See the "vagrant_vagrantfile" docs for more info.
      #
      # @return [String]
      attr_accessor :vagrant_machine

      # The path to the Vagrantfile that contains a VM that will be
      # started as the Docker host if needed (Windows, OS X, Linux
      # without container support).
      #
      # Defaults to a built-in Vagrantfile that will load boot2docker.
      #
      # NOTE: This only has an effect if Vagrant needs a Docker host.
      # Vagrant determines this automatically based on the environment
      # it is running in.
      #
      # @return [String]
      attr_accessor :vagrant_vagrantfile

      def initialize
        @build_dir  = UNSET_VALUE
        @cmd        = UNSET_VALUE
        @create_args = []
        @env        = {}
        @has_ssh    = UNSET_VALUE
        @image      = UNSET_VALUE
        @name       = UNSET_VALUE
        @links      = []
        @ports      = []
        @privileged = UNSET_VALUE
        @remains_running = UNSET_VALUE
        @volumes    = []
        @vagrant_machine = UNSET_VALUE
        @vagrant_vagrantfile = UNSET_VALUE
      end

      def link(name)
        @links << name
      end

      def merge(other)
        super.tap do |result|
          env = {}
          env.merge!(@env) if @env
          env.merge!(other.env) if other.env
          result.env = env

          links = _links.dup
          links += other._links
          result.instance_variable_set(:@links, links)
        end
      end

      def finalize!
        @build_dir  = nil if @build_dir == UNSET_VALUE
        @cmd        = [] if @cmd == UNSET_VALUE
        @create_args = [] if @create_args == UNSET_VALUE
        @env       ||= {}
        @has_ssh    = false if @has_ssh == UNSET_VALUE
        @image      = nil if @image == UNSET_VALUE
        @name       = nil if @name == UNSET_VALUE
        @privileged = false if @privileged == UNSET_VALUE
        @remains_running = true if @remains_running == UNSET_VALUE
        @vagrant_machine = nil if @vagrant_machine == UNSET_VALUE
        @vagrant_vagrantfile = nil if @vagrant_vagrantfile == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        @links.each do |link|
          parts = link.split(":")
          if parts.length != 2 || parts[0] == "" || parts[1] == ""
            errors << I18n.t(
              "docker_provider.errors.config.invalid_link", link: link)
          end
        end

        # TODO: Detect if base image has a CMD / ENTRYPOINT set before erroring out
        errors << I18n.t("docker_provider.errors.config.cmd_not_set") if @cmd == UNSET_VALUE

        { "docker provider" => errors }
      end

      #--------------------------------------------------------------
      # Functions below should not be called by config files
      #--------------------------------------------------------------

      def _links
        @links
      end
    end
  end
end
