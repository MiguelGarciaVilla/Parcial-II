defmodule Servidor do
  def iniciar() do
    Process.register(self(), :servicio_sismos)
    IO.puts("Servidor iniciado. Esperando consultas")
    ciclo_espera()
  end

  defp ciclo_espera() do
    receive do
      {cliente, :reporte_general} ->
        # adaptacion para el coordinador para devolver string en vez de un archivo
        texto = generar_texto_servidor(nil)
        send(cliente, {:respuesta, texto})
        ciclo_espera()

      {cliente, {:reporte_ciudad, id_ciudad}} ->
        texto = generar_texto_servidor(id_ciudad)
        send(cliente, {:respuesta, texto})
        ciclo_espera()

      {cliente, :fin} ->
        send(cliente, {:respuesta, "Comunicación finalizada por el servidor."})
        ciclo_espera()
    end
  end

  defp generar_texto_servidor(filtro_id) do
    case {Csv.leer_con_rechazos("resources/ciudades.txt", &Ciudad.parse/1),
          Csv.leer_con_rechazos("resources/movimientos.txt", &Movimiento.parse/1)} do
      {{:ok, ciudades, rc}, {:ok, movs, rm}} ->
        if filtro_id == nil do
          Reporte.generar(ciudades, movs, rc, rm)
        else
          case Enum.find(ciudades, &(&1.id == filtro_id)) do
            nil -> "La ciudad no está registrada"
            ciudad -> Reporte.generar([ciudad], movs, 0, 0)
          end
        end
      {{:error, ruta}, _} -> "Error del servidor: No se pudo leer #{ruta}"
      {_, {:error, ruta}} -> "Error del servidor: No se pudo leer #{ruta}"
    end
  end
end
