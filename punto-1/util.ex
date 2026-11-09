defmodule Util do
  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end

  def mostrar_mensaje_java(mensaje) do
    System.cmd("java", ["-cp", ".", "Mensaje", mensaje])
  end

  # pattern matching
  # atomo
  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def ingresar(mensaje, :entero) do
    ingresar(mensaje, &String.to_integer/1, :entero)
  end

  def ingresar(mensaje, :boolean) do
    resultado= ingresar(mensaje,:texto)
    case String.downcase(resultado) do
      "s" -> true
      "n" -> false
      _   -> {:error, "Entrada inválida. Debe ser 's' o 'n'."}
    end
  end


  def ingresar(mensaje, :real) do
    ingresar(mensaje, &String.to_float/1, :real)
  end


  def ingresar(mensaje, parser, tipo_dato) do
    try do
      mensaje
      |> ingresar(:texto)
      |> parser.()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un número #{tipo_dato}\n"
        |> mostrar_error()

        mensaje
        |> ingresar(parser, tipo_dato)
    end
  end

  def formater(valor) do
    :io_lib.format("~.2f", [valor]) |> List.to_string()
  end

  def parse_float(cadena) do
    cadena
    |> String.trim()
    |> Float.parse()
    |> case do
      {numero, _resto} -> numero
      :error -> :error
    end
  end
end
