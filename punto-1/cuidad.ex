defmodule Ciudad do
  defstruct idCiudad: "", nombre: "", habitantes: 0

  def crear(idCiudad, nombre, habitantes) do
    %Ciudad{idCiudad: idCiudad, nombre: nombre, habitantes: habitantes}
  end

  def convertir_ciudad_linea(ciudad) do
    "#{ciudad.idCiudad}@#{ciudad.nombre}@#{ciudad.habitantes}"
  end

  def convertir_linea_ciudad(linea) do
    [idCiudad, nombre, habitantes] =
      linea
      |> String.split("@")
      |> Enum.map(&String.trim/1)
    habitantes = String.to_integer(habitantes)
    if validar_habitantes(habitantes) do
      crear(idCiudad, nombre, habitantes)
    else
      :error
    end
  end

  defp validar_habitantes(habitantes) do
    cond do
      habitantes > 0  and is_integer(habitantes) -> true
      _ -> false
    end
  end

end
