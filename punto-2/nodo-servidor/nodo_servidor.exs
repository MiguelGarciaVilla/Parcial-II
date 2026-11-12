defmodule Servidor do
  @nombre_servicio_local :servicio_sismos
  @ruta_ciudades "punto-2/nodo-servidor/resources/ciudades.txt"
  @ruta_movimientos "punto-2/nodo-servidor/resources/movimientos.txt"

  def main() do
    Util.mostrar_mensaje("PROCESO SERVIDOR: esperando consultas")
    registrar_servicio(@nombre_servicio_local)
    procesar_mensajes()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  defp procesar_mensajes() do
    receive do
      {cliente, mensaje} ->
        respuesta = procesar_mensaje(mensaje)
        send(cliente, respuesta)

        # Llama recursivamente para seguir atendiendo consultas
        procesar_mensajes()
    end
  end

  # Adaptación para el coordinador: devuelve un string en vez de un archivo
  defp procesar_mensaje(:reporte_general), do: {:respuesta, generar_texto(nil)}

  defp procesar_mensaje({:reporte_ciudad, id_ciudad}),
    do: {:respuesta, generar_texto(id_ciudad)}

  defp procesar_mensaje(:fin), do: {:fin, "Comunicación finalizada por el servidor."}

  defp procesar_mensaje(mensaje),
    do: {:respuesta, "El mensaje \"#{inspect(mensaje)}\" es desconocido."}

  defp generar_texto(filtro_id) do
    case {Csv.leer_con_rechazos(@ruta_ciudades, &Ciudad.parse/1),
          Csv.leer_con_rechazos(@ruta_movimientos, &Movimiento.parse/1)} do
      {{:ok, ciudades, rc}, {:ok, movs, rm}} ->
        armar_reporte(filtro_id, ciudades, movs, rc, rm)

      {{:error, ruta}, _} ->
        "Error del servidor: No se pudo leer #{ruta}"

      {_, {:error, ruta}} ->
        "Error del servidor: No se pudo leer #{ruta}"
    end
  end

  # Sin filtro: reporte de todas las ciudades
  defp armar_reporte(nil, ciudades, movs, rc, rm),
    do: Reporte.generar(ciudades, movs, rc, rm)

  # Con filtro: reporte de una sola ciudad
  defp armar_reporte(id_ciudad, ciudades, movs, _rc, _rm) do
    case Enum.find(ciudades, &(&1.id == id_ciudad)) do
      nil -> "La ciudad no está registrada"
      ciudad -> Reporte.generar([ciudad], movs, 0, 0)
    end
  end
end
