Code.require_file("csv.exs", __DIR__)

defmodule Persistencia do
  @nombre_archivo "data-ciudad.csv"
  @titulos "idCiudad, nombre, habitantes\n"

  def guardar(data, convertir_ciudad_linea) do
    Csv.escribir_csv(data, @nombre_archivo, @titulos, convertir_ciudad_linea)
  end

  def cargar(convertir_linea_ciudad) when convertir_linea_ciudad != :error do
    Csv.leer_csv(@nombre_archivo, convertir_linea_ciudad)
  end

  def cargar(_convertir_linea_ciudad), do: :error
end
