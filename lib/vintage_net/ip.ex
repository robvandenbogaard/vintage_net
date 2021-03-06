defmodule VintageNet.IP do
  @moduledoc """
  This module contains utilities for handling IP addresses.

  By far the most important part of handling IP addresses is to
  pay attention to whether your addresses are names, IP addresses
  as strings or IP addresses at tuples. This module doesn't resolve
  names. While IP addresses in string form are convenient to type,
  nearly all Erlang and Elixir code uses IP addresses in tuple
  form.
  """

  @doc """
  Convert an IP address to a string

  Examples:

      iex> VintageNet.IP.ip_to_string({192, 168, 0, 1})
      "192.168.0.1"

      iex> VintageNet.IP.ip_to_string("192.168.9.1")
      "192.168.9.1"

      iex> VintageNet.IP.ip_to_string({65152, 0, 0, 0, 0, 0, 0, 1})
      "fe80::1"
  """
  @spec ip_to_string(VintageNet.any_ip_address()) :: String.t()
  def ip_to_string(ipa) when is_tuple(ipa) do
    :inet.ntoa(ipa) |> List.to_string()
  end

  def ip_to_string(ipa) when is_binary(ipa), do: ipa

  @doc """
  Convert an IP address w/ prefix to a CIDR-formatted string

  Examples:

      iex> VintageNet.IP.cidr_to_string({192, 168, 0, 1}, 24)
      "192.168.0.1/24"
  """
  @spec cidr_to_string(:inet.ip_address(), VintageNet.prefix_length()) :: String.t()
  def cidr_to_string(ipa, bits) do
    ip_to_string(ipa) <> "/" <> Integer.to_string(bits)
  end

  @doc """
  Convert an IP address to tuple form

  Examples:

      iex> VintageNet.IP.ip_to_tuple("192.168.0.1")
      {:ok, {192, 168, 0, 1}}

      iex> VintageNet.IP.ip_to_tuple({192, 168, 1, 1})
      {:ok, {192, 168, 1, 1}}

      iex> VintageNet.IP.ip_to_tuple("fe80::1")
      {:ok, {65152, 0, 0, 0, 0, 0, 0, 1}}

      iex> VintageNet.IP.ip_to_tuple({65152, 0, 0, 0, 0, 0, 0, 1})
      {:ok, {65152, 0, 0, 0, 0, 0, 0, 1}}

      iex> VintageNet.IP.ip_to_tuple("bologna")
      {:error, "Invalid IP address: bologna"}
  """
  @spec ip_to_tuple(VintageNet.any_ip_address()) ::
          {:ok, :inet.ip_address()} | {:error, String.t()}
  def ip_to_tuple({a, b, c, d} = ipa)
      when a >= 0 and a <= 255 and b >= 0 and b <= 255 and c >= 0 and c <= 255 and d >= 0 and
             d <= 255,
      do: {:ok, ipa}

  def ip_to_tuple({a, b, c, d, e, f, g, h} = ipa)
      when a >= 0 and a <= 65535 and b >= 0 and b <= 65535 and c >= 0 and c <= 65535 and d >= 0 and
             d <= 65535 and
             e >= 0 and e <= 65535 and f >= 0 and f <= 65535 and g >= 0 and g <= 65535 and h >= 0 and
             h <= 65535,
      do: {:ok, ipa}

  def ip_to_tuple(ipa) when is_binary(ipa) do
    case :inet.parse_address(to_charlist(ipa)) do
      {:ok, addr} -> {:ok, addr}
      {:error, :einval} -> {:error, "Invalid IP address: #{ipa}"}
    end
  end

  def ip_to_tuple(ipa), do: {:error, "Invalid IP address: #{inspect(ipa)}"}

  @doc """
  Raising version of ip_to_tuple/1
  """
  @spec ip_to_tuple!(VintageNet.any_ip_address()) :: :inet.ip_address()
  def ip_to_tuple!(ipa) do
    case ip_to_tuple(ipa) do
      {:ok, addr} ->
        addr

      {:error, error} ->
        raise ArgumentError, error
    end
  end

  @doc """
  Convert an IPv4 subnet mask to a prefix length.

  Examples:

      iex> VintageNet.IP.subnet_mask_to_prefix_length({255, 255, 255, 0})
      {:ok, 24}

      iex> VintageNet.IP.subnet_mask_to_prefix_length({192, 168, 1, 1})
      {:error, "{192, 168, 1, 1} is not a valid IPv4 subnet mask"}
  """
  @spec subnet_mask_to_prefix_length(:inet.ip4_address()) ::
          {:ok, VintageNet.ipv4_prefix_length()} | {:error, String.t()}
  def subnet_mask_to_prefix_length(subnet_mask) do
    # Not exactly efficient...
    lookup = for bits <- 0..32, into: %{}, do: {prefix_length_to_subnet_mask(:inet, bits), bits}

    case Map.get(lookup, subnet_mask) do
      nil -> {:error, "#{inspect(subnet_mask)} is not a valid IPv4 subnet mask"}
      bits -> {:ok, bits}
    end
  end

  @doc """
  Convert an IPv4 or IPv6 prefix length to a subnet mask.

  Examples:

      iex> VintageNet.IP.prefix_length_to_subnet_mask(:inet, 24)
      {255, 255, 255, 0}

      iex> VintageNet.IP.prefix_length_to_subnet_mask(:inet, 28)
      {255, 255, 255, 240}

      iex> VintageNet.IP.prefix_length_to_subnet_mask(:inet6, 64)
      {65535, 65535, 65535, 65535, 0, 0, 0, 0}
  """
  @spec prefix_length_to_subnet_mask(:inet | :inet6, VintageNet.prefix_length()) ::
          :inet.ip_address()
  def prefix_length_to_subnet_mask(:inet, len) when len >= 0 and len <= 32 do
    rest = 32 - len
    <<a, b, c, d>> = <<-1::size(len), 0::size(rest)>>
    {a, b, c, d}
  end

  def prefix_length_to_subnet_mask(:inet6, len) when len >= 0 and len <= 128 do
    rest = 128 - len

    <<a::size(16), b::size(16), c::size(16), d::size(16), e::size(16), f::size(16), g::size(16),
      h::size(16)>> = <<-1::size(len), 0::size(rest)>>

    {a, b, c, d, e, f, g, h}
  end

  @doc """
  Utility function to trim an IP address to its subnet

  Examples:

      iex> VintageNet.IP.to_subnet({192, 168, 1, 50}, 24)
      {192, 168, 1, 0}

      iex> VintageNet.IP.to_subnet({192, 168, 255, 50}, 22)
      {192, 168, 252, 0}
  """
  @spec to_subnet(:inet.ip_address(), VintageNet.prefix_length()) :: :inet.ip_address()
  def to_subnet({a, b, c, d}, subnet_bits) when subnet_bits >= 0 and subnet_bits < 32 do
    not_subnet_bits = 32 - subnet_bits
    <<subnet::size(subnet_bits), _::size(not_subnet_bits)>> = <<a, b, c, d>>
    <<new_a, new_b, new_c, new_d>> = <<subnet::size(subnet_bits), 0::size(not_subnet_bits)>>
    {new_a, new_b, new_c, new_d}
  end
end
