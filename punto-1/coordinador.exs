defmodule Coordinador do
  def reporte_local() do
    coordinador = self()

    # Trabajadores concurrentes
    spawn(fn -> send(coordinador, {:resultado_ciudades, Csv.leer_con_rechazos("resources/ciudades.txt", &Ciudad.parse/1)}) end)
    spawn(fn -> send(coordinador, {:resultado_movs, Csv.leer_con_rechazos("resources/movimientos.txt", &Movimiento.parse/1)}) end)

    esperar_y_guardar(nil, nil)
  end

  defp esperar_y_guardar(res_cuidades, res_movs) when res_cuidades != nil and res_movs != nil do
    case {res_cuidades, res_movs} do
      {{:ok, ciudades, rechazados_c}, {:ok, movs, rechazados_m}} ->
        texto = Reporte.generar(ciudades, movs, rechazados_c, rechazados_m)
        IO.puts(texto)
        File.write!("resources/reporte_sismos.txt", texto)
        IO.puts("Reporte guardado exitosamente.")
      {{:error, ruta}, _} -> IO.puts("Error leyendo archivo: #{ruta}. Se conserva el reporte anterior.")
      {_, {:error, ruta}} -> IO.puts("Error leyendo archivo: #{ruta}. Se conserva el reporte anterior.")
    end
  end

  defp esperar_y_guardar(res_cuidades, res_movs) do
    receive do
      {:resultado_ciudades, data} -> esperar_y_guardar(data, res_movs)
      {:resultado_movs, data}     -> esperar_y_guardar(res_cuidades, data)
    end
  end
end
