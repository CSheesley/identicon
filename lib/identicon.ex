defmodule Identicon do
  @moduledoc """
    Provides a series of functions that are chained together in the `main()` function,
    which takes in a STRING argument, creates an Identicon, and saves it to a `.png` file.
  """

  @doc """
    This function takes in a STRING as an argument, and uses the remaining functions in
    this module to ultimate create and save an Identicon image based on the hex values of
    the STRING argument. Return value is `:ok`, and results in a `.png` file creation.

    iex> Identicon.main("asdf")
    iex> :ok
  """
  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """
    Once an 'Image' has been created with the `draw_image()` function, this function takes
    that Image, and the input to save the image as a `.png` file, using the `input` argument
    and adding a `.png` to the end. Ex: "asdf.png"

    Example:
      iex> image_struct = %Identicon.Image{ color: {145, 46, 200}, pixel_map: [ {{0, 0}, {50, 50}}, {{50, 0}, {100, 50}}, {{100, 0}, {150, 50}}, {{150, 0}, {200, 50}}, {{200, 0}, {250, 50}}, {{0, 50}, {50, 100}}, {{50, 50}, {100, 100}}, {{100, 50}, {150, 100}}, {{150, 50}, {200, 100}},  {{200, 50}, {250, 100}}, {{0, 100}, {50, 150}}, {{50, 100}, {100, 150}}, {{100, 100}, {150, 150}}, {{150, 100}, {200, 150}}, {{200, 100}, {250, 150}}, {{0, 150}, {50, 200}}, {{50, 150}, {100, 200}}, {{100, 150}, {150, 200}},  {{150, 150}, {200, 200}}, {{200, 150}, {250, 200}}, {{0, 200}, {50, 250}}, {{50, 200}, {100, 250}}, {{100, 200}, {150, 250}}, {{150, 200}, {200, 250}}, {{200, 200}, {250, 250}} ] }
      iex> image = Identicon.draw_image(image_struct)
      iex> Identicon.save_image(image, "asdf")
      iex> :ok
  """
  def save_image(image, input) do
    File.write("#{input}.png", image)
  end

  @doc """
    Using the `:color` and `:pixel_map` attributes from an an `Identicon.Image` STRUCT,
    this function used the `:egd` library to generate and render an Image - which then
    needs to be saved in order to open. Output is an Image, and no longer an `Identicon.Image` STRUCT.
  """
  def draw_image(%Identicon.Image{ color: color, pixel_map: pixel_map }) do
    image = :egd.create(250, 250)
    fill  = :egd.color(color)

    Enum.each pixel_map, fn({ start, stop }) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  @doc """
    Using the `:grid` attributes from an an `Identicon.Image` STRUCT, this function
    maps out the pixel coordinates for where rectangels should be drawn, storing these in the
    `:pixel_map` attribute in an `Identicon.Image` STRUCT.

    Example:
      iex> image_struct = %Identicon.Image{ grid: [ {145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, {3, 5}, {178, 6}, {206, 7}, {178, 8}, {3, 9}, {73, 10}, {228, 11}, {165, 12}, {228, 13}, {73, 14}, {65, 15}, {6, 16}, {141, 17}, {6, 18}, {65, 19}, {73, 20}, {90, 21}, {181, 22}, {90, 23}, {73, 24} ] }
      iex> Identicon.build_pixel_map(image_struct)
      iex> %Identicon.Image{color: nil, grid: [ {145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, {3, 5}, {178, 6}, {206, 7}, {178, 8}, {3, 9}, {73, 10}, {228, 11}, {165, 12}, {228, 13}, {73, 14}, {65, 15}, {6, 16}, {141, 17}, {6, 18}, {65, 19}, {73, 20}, {90, 21}, {181, 22}, {90, 23}, {73, 24}], hex: nil, pixel_map: [ {{0, 0}, {50, 50}}, {{50, 0}, {100, 50}}, {{100, 0}, {150, 50}}, {{150, 0}, {200, 50}}, {{200, 0}, {250, 50}}, {{0, 50}, {50, 100}}, {{50, 50}, {100, 100}}, {{100, 50}, {150, 100}}, {{150, 50}, {200, 100}},  {{200, 50}, {250, 100}}, {{0, 100}, {50, 150}}, {{50, 100}, {100, 150}}, {{100, 100}, {150, 150}}, {{150, 100}, {200, 150}}, {{200, 100}, {250, 150}}, {{0, 150}, {50, 200}}, {{50, 150}, {100, 200}}, {{100, 150}, {150, 200}},  {{150, 150}, {200, 200}}, {{200, 150}, {250, 200}}, {{0, 200}, {50, 250}}, {{50, 200}, {100, 250}}, {{100, 200}, {150, 250}}, {{150, 200}, {200, 250}}, {{200, 200}, {250, 250}} ] }
  """
  def build_pixel_map(%Identicon.Image{ grid: grid } = image_struct) do
    pixel_map = Enum.map grid, fn({ _code, index }) ->
      horizontal = rem(index, 5) * 50
      vertical   = div(index, 5) * 50

      top_left     = { horizontal, vertical }
      bottom_right = { horizontal + 50, vertical + 50}

      { top_left, bottom_right }
    end

    %Identicon.Image{ image_struct | pixel_map: pixel_map }
  end

  @doc """
    Using the `:grid` attributes from an an `Identicon.Image` STRUCT, filters out TUPLEs
    where the (color) code is odd, and stores this new set of TUPLEs in the `:grid` attribute in an `Identicon.Image` STRUCT.

    Example:
      iex> image_struct = %Identicon.Image{ grid: [ {145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, {3, 5}, {178, 6}, {206, 7}, {178, 8}, {3, 9}, {73, 10}, {228, 11}, {165, 12}, {228, 13}, {73, 14}, {65, 15}, {6, 16}, {141, 17}, {6, 18}, {65, 19}, {73, 20}, {90, 21}, {181, 22}, {90, 23}, {73, 24} ] }
      iex> Identicon.filter_odd_squares(image_struct)
      iex> %Identicon.Image{ color: nil, grid: [ {46, 1}, {200, 2}, {46, 3}, {178, 6}, {206, 7}, {178, 8}, {228, 11}, {228, 13}, {6, 16}, {6, 18}, {90, 21}, {90, 23} ], hex: nil, pixel_map: nil }
  """
  def filter_odd_squares(%Identicon.Image{ grid: grid } = image_struct) do
    grid = Enum.filter grid, fn({ code, _index }) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{ image_struct | grid: grid }
  end

  @doc """
    Using the `:hex` attributes from an an `Identicon.Image` STRUCT, creates a set of TUPLEs
    each indicating { code, index }, storing them as the `:grid` attribute in an `Identicon.Image` STRUCT.

    Example:
      iex> image_struct = %Identicon.Image{ hex: [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112] }
      iex> Identicon.build_grid(image_struct)
      iex> %Identicon.Image{ color: nil, grid: [ {145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, {3, 5}, {178, 6}, {206, 7}, {178, 8}, {3, 9}, {73, 10}, {228, 11}, {165, 12}, {228, 13}, {73, 14}, {65, 15}, {6, 16}, {141, 17}, {6, 18}, {65, 19}, {73, 20}, {90, 21}, {181, 22}, {90, 23}, {73, 24} ], hex: [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112], pixel_map: nil }
  """
  def build_grid(%Identicon.Image{ hex: hex } = image_struct) do
    grid =
      hex
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{ image_struct | grid: grid }
  end

  @doc """
    Takes a LIST as an argument, mirrors the first two elements, and adds them to the end of a LIST.

    Example:
      iex> list = [145, 46, 200]
      iex> Identicon.mirror_row(list)
      iex> [145, 46, 200, 46, 145]
  """
  def mirror_row(row) do
    [first, second | _tail] = row

    row ++ [second, first]
  end

  @doc """
    Using the `:hex` attributes from an an `Identicon.Image` STRUCT, determines(r)ed, (g)reen, (b)lue values,
    storing them as the `:color` attribute in an `Identicon.Image` STRUCT.

    Example:
      iex> image_struct = %Identicon.Image{ hex: [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112] }
      iex> Identicon.pick_color(image_struct)
      iex> %Identicon.Image{ color: {145, 46, 200}, grid: nil, hex: [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112], pixel_map: nil }
  """
  def pick_color(%Identicon.Image{ hex: [r, g, b | _tail] } = image_struct) do
    %Identicon.Image{ image_struct | color: { r, g, b} }
  end

  @doc """
    Creates a hex map, which is stored as the `:hex` attribute in an `Identicon.Image` STRUCT.

    Example:
      iex> Identicon.hash_input("asdf")
      iex> %Identicon.Image{ color: nil, grid: nil, hex: [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112], pixel_map: nil }
  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{ hex: hex }
  end
end
