require "kubeflow/command/base"

# list commands and display help
#
class Kubeflow::Command::Help < Kubeflow::Command::Base

  PRIMARY_NAMESPACES = %w( auth apps ps run restart addons config releases domains logs sharing )

  # help [COMMAND]
  #
  # list available commands or display help for a specific command
  #
  #Examples:
  #
  # $ kubeflow help
  # Usage: kubeflow COMMAND [--app APP] [command-specific-options]
  #
  # Primary help topics, type "kubeflow help TOPIC" for more details:
  #
  #   addons    #  manage addon resources
  #   apps      #  manage apps (create, destroy)
  #   ...
  #
  # Additional topics:
  #
  #   account      #  manage kubeflow account options
  #   accounts     #  manage multiple kubeflow accounts
  #   ...
  #
  # $ kubeflow help apps:create
  # Usage: kubeflow apps:create [NAME]
  #
  #  create a new app
  #
  #      --addons ADDONS        # a comma-delimited list of addons to install
  #  -b, --buildpack BUILDPACK  # a buildpack url to use for this app
  #  -r, --remote REMOTE        # the git remote to create, default "kubeflow"
  #
  def index
    if command = args.shift
      help_for_command(command)
    else
      help_for_root
    end
  end

  alias_command "-h", "help"
  alias_command "--help", "help"

private

  def commands_for_namespace(name)
    Kubeflow::Command.commands.values.select do |command|
      command[:namespace] == name && command[:command] != name
    end
  end

  def namespaces
    namespaces = Kubeflow::Command.namespaces
    namespaces.delete("app")
    namespaces
  end

  def commands
    Kubeflow::Command.commands
  end

  def skip_namespace?(ns)
    return true if ns[:description] =~ /DEPRECATED:/
    return true if ns[:description] =~ /HIDDEN:/
    false
  end

  def skip_command?(command)
    return true if command[:help] =~ /DEPRECATED:/
    return true if command[:help] =~ /^ HIDDEN:/
    return true if command[:hidden]
    false
  end

  def primary_namespaces
    PRIMARY_NAMESPACES.map { |name| namespaces[name] }.compact
  end

  def additional_namespaces
    (namespaces.values - primary_namespaces)
  end

  def summary_for_namespaces(namespaces)
    size = longest(namespaces.map { |n| n[:name] })
    namespaces.sort_by {|namespace| namespace[:name]}.each do |namespace|
      next if skip_namespace?(namespace)
      name = namespace[:name]
      puts "  %-#{size}s  # %s" % [ name, namespace[:description] ]
    end
  end

  def help_for_root
    puts "Usage: kubeflow COMMAND [--app APP] [command-specific-options]"
    puts
    puts "Primary help topics, type \"kubeflow help TOPIC\" for more details:"
    puts
    summary_for_namespaces(primary_namespaces)
    puts
    puts "Additional topics:"
    puts
    summary_for_namespaces(additional_namespaces)
    puts
  end

  def help_for_namespace(name)
    namespace_commands = commands_for_namespace(name)

    unless namespace_commands.empty?
      size = longest(namespace_commands.map { |c| c[:banner] })
      namespace_commands.sort_by { |c| c[:banner].to_s }.each do |command|
        next if skip_command?(command)
        puts "  %-#{size}s  # %s" % [ command[:banner], command[:summary] ]
      end
    end
  end

  def help_for_command(name)
    if command_alias = Kubeflow::Command.command_aliases[name]
      display("Alias: #{name} redirects to #{command_alias}")
      name = command_alias
    end
    if command = commands[name]
      puts "Usage: kubeflow #{command[:banner]}"

      if command[:help].strip.length > 0
        help = command[:help].split("\n").reject do |line|
          line =~ /HIDDEN/
        end
        puts help[1..-1].join("\n")
      else
        puts "no help"
      end
      puts
    end

    namespace_commands = commands_for_namespace(name).reject do |command|
      command[:help] =~ /DEPRECATED/
    end

    if !namespace_commands.empty?
      puts "Additional commands, type \"kubeflow help COMMAND\" for more details:"
      puts
      help_for_namespace(name)
      puts
    elsif command.nil?
      error "#{name} is not a kubeflow command. See `kubeflow help`."
    end
  end
end
