defmodule Cliente do
  @nombre_servicio_local :servicio_respuesta
  @servicio_local {@nombre_servicio_local, :nodocliente@localhost}
  @nodo_remoto :nodoservidor@localhost
  @servicio_remoto {:servicio_sismos, @nodo_remoto}

  # Consultas exigidas, en el orden específico que se indica en el documento
  @mensajes [
    # Con movimientos
    {:reporte_ciudad, "C01"},
    # Sin movimientos
    {:reporte_ciudad, "C03"},
    # Inexistente
    {:reporte_ciudad, "C99"},
    :reporte_general,
    :fin
  ]

  def main() do
    IO.puts("PROCESO CLIENTE")

    @nombre_servicio_local
    |> registrar_servicio()

    establecer_conexion(@nodo_remoto)
    |> iniciar_produccion()
  end

  defp registrar_servicio(nombre_servicio_local),
    do: Process.register(self(), nombre_servicio_local)

  defp establecer_conexion(nodo_remoto), do: Node.connect(nodo_remoto)

  defp iniciar_produccion(true) do
    enviar_mensajes()
    recibir_respuestas()
  end

  # Cubre false (no hubo conexión) y :ignored (este nodo no se inició con --sname)
  defp iniciar_produccion(_),
    do: IO.puts(:standard_error, "No se pudo conectar con el nodo servidor")

  defp enviar_mensajes() do
    Enum.each(@mensajes, &enviar_mensaje/1)
  end

  defp enviar_mensaje(mensaje) do
    send(@servicio_remoto, {@servicio_local, mensaje})
  end

  defp recibir_respuestas() do
    receive do
      {:fin, texto} ->
        IO.puts("\nFIN\n#{texto}")

      {:respuesta, texto} ->
        IO.puts("\nRESPUESTA\n#{texto}")
        recibir_respuestas()
    end
  end
end
Cliente.main()
