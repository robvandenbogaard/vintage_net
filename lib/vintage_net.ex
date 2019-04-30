defmodule VintageNet do
  @moduledoc """
  VintageNet configures network interfaces using Linux utilities


  """
  alias VintageNet.Interface

  @doc """
  Return a list of interface names that have been configured
  """
  @spec get_interfaces() :: [String.t()]
  def get_interfaces() do
    for {[_interface, ifname | _rest], _value} <-
          PropertyTable.get_by_prefix(VintageNet, ["interface"]) do
      ifname
    end
    |> Enum.uniq()
  end

  @doc """
  Update the settings for the specified interface
  """
  @spec configure(String.t(), map()) :: :ok | {:error, any()}
  def configure(ifname, config) do
    case autostart_interface(ifname) do
      :ok -> Interface.configure(ifname, config)
      error -> error
    end
  end

  @doc """
  Return the settings for the specified interface
  """
  @spec get_configuration(String.t()) :: map()
  def get_configuration(ifname) do
    Interface.get_configuration(ifname)
  end

  @doc """
  Check if this is a valid configuration

  This runs the validation routines for a settings map, but doesn't try
  to apply them.
  """
  @spec configuration_valid?(String.t(), map()) :: boolean()
  def configuration_valid?(ifname, config) do
    opts = Application.get_all_env(:vintage_net)

    with {:ok, technology} <- Map.fetch(config, :type),
         {:ok, _raw_config} <- technology.to_raw_config(ifname, config, opts) do
      true
    else
      _ -> false
    end
  end

  @doc """
  Scan wireless interface for other access points
  """
  @spec scan(String.t()) :: {:ok, [String.t()]} | {:error, String.t()}
  def scan(ifname) do
    Interface.ioctl(ifname, :scan)
  end

  @doc """
  Check that the system has the required programs installed

  """
  @spec verify_system([atom()] | atom(), keyword()) :: :ok | {:error, any()}
  def verify_system(types, opts) when is_list(types) do
    # TODO...Fix with whatever the right Enum thing is.
    with :ok <- verify_system(:ethernet, opts) do
      :ok
    end
  end

  def verify_system(:ethernet, opts) do
    with :ok <- check_program(opts[:bin_ifup]) do
      :ok
    end
  end

  def verify_system(:wifi, opts) do
    with :ok <- check_program(opts[:bin_ifup]) do
      :ok
    end
  end

  def verify_system(:wifi_ap, opts) do
    with :ok <- check_program(opts[:bin_ifup]) do
      :ok
    end
  end

  def verify_system(:mobile, opts) do
    with :ok <- check_program(opts[:bin_ifup]) do
      :ok
    end
  end

  defp check_program(path) do
    if File.exists?(path) do
      :ok
    else
      {:error, "Can't find #{path}"}
    end
  end

  defp autostart_interface(ifname) do
    case VintageNet.InterfacesSupervisor.start_interface(ifname) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pi}} -> :ok
      error -> error
    end
  end
end
