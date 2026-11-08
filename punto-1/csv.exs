defmodule Csv do
  def escribir_csv(data, file_path, titulos, convertir_algo_linea) do
    data
    |> generar_mensaje_csv(convertir_algo_linea)
    |> (&(titulos <> &1)).()
    |> (&(File.write(file_path, &1))).()
  end

  def leer_csv(file_path, convertir_linea_algo) do
    File.stream!(file_path)
    |> Enum.drop(1)
    |> Enum.map(convertir_linea_algo)
  end

  def generar_mensaje_csv(data, convertir_algo_linea) do
    data
    |> Enum.map(convertir_algo_linea)
    |> Enum.join("\n")
  end
end
