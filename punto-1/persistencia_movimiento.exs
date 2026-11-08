Code.require_file("csv.exs", __DIR__)

defmodule Persistencia do
  @nombre_archivo "data-movimiento.csv"
  @titulos "codigo, idCiudad, horaInicio, horaFin, magnitud, profundidad\n"

  def guardar(data, convertir_movimiento_linea) do
    Csv.escribir_csv(data, @nombre_archivo, @titulos, convertir_movimiento_linea)
  end

  def cargar(convertir_linea_movimiento) when convertir_linea_movimiento != :error do
    Csv.leer_csv(@nombre_archivo, convertir_linea_movimiento)
  end

  def cargar(_convertir_linea_movimiento), do: :error
end
