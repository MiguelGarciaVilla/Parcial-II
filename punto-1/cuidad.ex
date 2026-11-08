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

    crear(idCiudad, nombre, habitantes)
  end

end
