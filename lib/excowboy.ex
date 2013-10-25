defmodule Mix.Tasks.Excowboy do
    use Mix.Task

    import Mix.Generator
    import Mix.Utils, only: [camelize: 1, underscore: 1]

    defmodule Generate do
      def run(argv) do
        { opts, argv, _ } = OptionParser.parse(argv, switches: [bare: :boolean, umbrella: :boolean])

        IO.puts inspect argv
        case argv do
          [] ->
            IO.puts "no args"
          [path|_] ->
            name = Path.basename(Path.expand(path))
            check_project_name!(name)
						File.mkdir_p!(path)
						File.cd! path, fn -> do_generate(name, opts) end
        end
      end

      defp do_generate(app, opts) do
				mod     = opts[:module] || camelize(app)
				assigns = [app: app, mod: mod]

				create_file "README.md",  readme_template(assigns)
				create_file ".gitignore", gitignore_text
				create_file "mix.exs", mixfile_template(assigns)

				create_directory "lib"
				create_file "lib/#{app}.ex", lib_app_template(assigns)
				create_directory "lib/#{app}"
				create_file "lib/#{app}/supervisor.ex", lib_supervisor_template(assigns)
				create_file "lib/#{app}/top_page_handler.ex", lib_handler_template(assigns)

				create_directory "test"
				create_file "test/test_helper.exs", test_helper_template(assigns)
				create_file "test/#{app}_test.exs", test_lib_template(assigns)

				Mix.shell.info """

    Your cowboy skeleton project is ready!
    You can use mix to compile it, test it, and more:

        cd #{path}
        mix compile
        mix test

    To run it;

       mix run --no-halt

    And point your browser at http://localhost:8080

    Run `mix help` for more information.
    """

      end

      defp check_project_name!(name) do
        unless name =~ %r/^[a-z][\w_]*$/ do
          raise Mix.Error, message: "Project path must start with a letter and have only lowercase letters, numbers and underscore"
        end
      end

			embed_template :readme, """
   # <%= @mod %>

   ** TODO: Add description **
   """

			embed_text :gitignore, """
   /ebin
   /deps
   erl_crash.dump
   *.ez
   """
			
			embed_template :mixfile, """
  defmodule <%= @mod %>.Mixfile do
    use Mix.Project

    def project do
      [ app: :<%= @app %>,
        version: "0.0.1",
        elixir: "~> <%= System.version %>",
        deps: deps ]
    end

    # Configuration for the OTP application
    def application do
      [ mod: { <%= @mod %>, [] },
        applications: [:cowboy] ]
    end

    # Returns the list of dependencies in the format:
    # { :foobar, "~> 0.1", git: "https://github.com/elixir-lang/foobar.git" }
    defp deps do
      [ {:cowboy, github: "extend/cowboy"} ]
    end
  end
  """

			embed_template :lib, """
  defmodule <%= @mod %> do
  end
  """

			embed_template :lib_app, """
  defmodule <%= @mod %> do
    use Application.Behaviour

    # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
    # for more information on OTP Applications
    def start(_type, _args) do
      dispatch = :cowboy_router.compile([
                   {:_, [{"/", <%= @mod %>.TopPageHandler, []}]}
                 ])
      {:ok, _} = :cowboy.start_http(:http, 100,
                                    [port: 8080],
                                    [env: [dispatch: dispatch]])
      <%= @mod %>.Supervisor.start_link
    end
  end
  """

			embed_template :lib_supervisor, """
  defmodule <%= @mod %>.Supervisor do
    use Supervisor.Behaviour

    def start_link do
      :supervisor.start_link(__MODULE__, [])
    end

    def init([]) do
      children = [
        # Define workers and child supervisors to be supervised
        # worker(<%= @mod %>.Worker, [])
      ]

      # See http://elixir-lang.org/docs/stable/Supervisor.Behaviour.html
      # for other strategies and supported options
      supervise(children, strategy: :one_for_one)
    end
  end
  """
			embed_template :lib_handler, """
  defmodule <%= @mod %>.TopPageHandler do
    def init(_transport, req, []) do
      {:ok, req, nil}
    end

    def handle(req, state) do
      {:ok, req} = :cowboy_req.reply(200, [], "Howdy, partner!", req)
      {:ok, req, state}
    end

    def terminate(_reason, _req, _state), do: :ok
  end
"""
			embed_template :test_lib, """
  defmodule <%= @mod %>Test do
    use ExUnit.Case

    test "the truth" do
      assert(true)
    end
  end
  """

			embed_template :test_helper, """
  ExUnit.start
  """
    end


end
