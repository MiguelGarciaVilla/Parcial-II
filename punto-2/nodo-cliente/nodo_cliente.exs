defmodule Cliente do
  def iniciar(nodo_servidor) do
    Process.register(self(), :servicio_respuesta)

    if Node.connect(nodo_servidor) do
      servidor = {:servicio_sismos, nodo_servidor}
      yo = {:servicio_respuesta, Node.self()}

      #consultas exigidas en el orden específico que se indica en el documento
      send(servidor, {yo, {:reporte_ciudad, "C01"}}) # Con movimientos
      send(servidor, {yo, {:reporte_ciudad, "C03"}}) # Sin movimientos
      send(servidor, {yo, {:reporte_ciudad, "C99"}}) # Inexistente
      send(servidor, {yo, :reporte_general})
      send(servidor, {yo, :fin})

      recibir_respuestas()
    else
      IO.puts("No se pudo conectar al servidor")
    end
  end

  defp recibir_respuestas() do
    receive do
      {:respuesta, "Comunicación finalizada por el servidor." = msg} ->
        IO.puts("\nFIN\n#{msg}")
      {:respuesta, texto} ->
        IO.puts("\nRESPUESTA\n#{texto}")
        recibir_respuestas()
    end
  end
end
