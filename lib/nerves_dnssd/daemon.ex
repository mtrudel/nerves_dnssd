defmodule Nerves.Dnssd.Daemon do
  @moduledoc """
  This process starts and manages the lifecycle of the
  mDNS "daemon".

  It is started as part of the `nerves_dnssd` application.
  """

  require Logger

  @doc "Start the mDNS daemon process"
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  ## Server callbacks

  @doc false
  def init([]) do
    port = Port.open({:spawn_executable, :code.priv_dir(:nerves_dnssd) ++ '/sbin/mdnsd'},
                     [:exit_status, :stderr_to_stdout, line: 256])
    {:ok, port}
  end

  @doc false
  def handle_info({_port, {:data, {:eol, 'ERROR: ' ++ message}}}, port) do
    Logger.error message
    {:noreply, port}
  end

  @doc false
  def handle_info({_port, {:data, {:eol, 'WARNING: ' ++ message}}}, port) do
    Logger.warn message
    {:noreply, port}
  end

  @doc false
  def handle_info({_port, {:data, {:eol, message}}}, port) do
    Logger.info message
    {:noreply, port}
  end

  @doc false
  def handle_info({port, {:exit_status, 0}}, port) do
    {:stop, :normal, port}
  end

  @doc false
  def handle_info({port, {:exit_status, status}}, port) do
    Logger.warn "mdns server stopped with exit code #{status}, #{Port.info(port)}"
    {:stop, {:mdnsd_exited, status}, port}
  end

  @doc false
  def handle_info(info, port) do
    Logger.warn "Unexpected message: #{inspect info}"
    {:noreply, port}
  end

end
