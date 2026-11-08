defmodule Csv do
  # Lee el archivo y separa los registros válidos de los rechazados
  def leer_con_rechazos(ruta, funcion_parse) do
    case File.read(ruta) do
      {:ok, contenido} ->
        lineas = String.split(contenido, "\n", trim: true)
        {validos, rechazados} = procesar_lineas(lineas, funcion_parse, [], 0)
        {:ok, Enum.reverse(validos), rechazados}
      {:error, _} ->
        {:error, ruta}
    end
  end

  defp procesar_lineas([], _funcion, validos, rechazados), do: {validos, rechazados}
  
  defp procesar_lineas([linea | resto], funcion, validos, rechazados) do
    case funcion.(linea) do
      {:ok, dato} -> procesar_lineas(resto, funcion, [dato | validos], rechazados)
      :error -> procesar_lineas(resto, funcion, validos, rechazados + 1)
    end
  end
end
