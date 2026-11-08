defmodule Ciudad do
  defstruct [:id, :nombre, :habitantes]

  def crear(id, nombre, habitantes) do
    %Ciudad{id: id, nombre: nombre, habitantes: habitantes}
  end

  def parse(linea) do
    case String.split(linea, "@") |> Enum.map(&String.trim/1) do
      [id, nombre, habitantes_str] ->
        case Integer.parse(habitantes_str) do
          {habitantes, ""} when habitantes > 0 -> {:ok, crear(id,nombre,habitantes)}
          _ -> :error
        end
      _ -> :error
    end
  end
end
