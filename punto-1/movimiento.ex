defmodule Movimiento do
  defstruct [:codigo, :id_ciudad, :hora_inicio, :hora_fin, :magnitud, :profundidad]

  def crear(codigo,id_ciudad,hora_inicio,hora_fin,magnitud,profundidad) do
      %Movimiento{codigo: codigo, id_ciudad: id_ciudad, hora_inicio: hora_inicio, hora_fin: hora_fin, magnitud: magnitud, profundidad: profundidad}
    end

  def parse(linea) do
    case String.split(linea, "@") |> Enum.map(&String.trim/1) do
      [codigo, id_ciudad, h_inicio, h_fin, magnitud_str, profundidad_str] ->
        with {:ok, inicio} <- Time.from_iso8601(h_inicio),
             {:ok, fin} <- Time.from_iso8601(h_fin),
             {magnitud, ""} <- Float.parse(magnitud_str),
             {profundidad, ""} when profundidad >= 0.0 <- Float.parse(profundidad_str) do
          {:ok, crear(codigo,id_ciudad,inicio,fin,magnitud,profundidad)}
        else
          _ -> :error
        end
      _ -> :error
    end
  end
end
