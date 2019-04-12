defmodule VintageNetTest.LoggingUdhcpcHandler do
  @behaviour VintageNet.ToElixir.UdhcpcHandler

  require Logger

  @doc """
  """
  @impl true
  def deconfig(ifname, info) do
    Logger.debug("udhcpc.deconfig(#{ifname}): #{inspect(info)}")
    :ok
  end

  @doc """
  """
  @impl true
  def leasefail(ifname, info) do
    Logger.debug("udhcpc.leasefail(#{ifname}): #{inspect(info)}")
    :ok
  end

  @doc """
  """
  @impl true
  def nak(ifname, info) do
    Logger.debug("udhcpc.nak(#{ifname}): #{inspect(info)}")
    :ok
  end

  @doc """
  """
  @impl true
  def renew(ifname, info) do
    Logger.debug("udhcpc.renew(#{ifname}): #{inspect(info)}")
    :ok
  end

  @doc """
  """
  @impl true
  def bound(ifname, info) do
    Logger.debug("udhcpc.bound(#{ifname}): #{inspect(info)}")
    :ok
  end
end
