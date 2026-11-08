defmodule Movimiento do
    defstruct codigo: "", idCiudad: "", horaInicio: ~T[00:00:00], horaFin: ~T[00:00:00], magnitud: 0.0, profundidad: 1

    def crear(codigo,idCiudad,horaInicio,horaFin,magnitud,profundidad) do
      %Movimiento{codigo: codigo, idCiudad: idCiudad, horaInicio: horaInicio, horaFin: horaFin, magnitud: magnitud, profundidad: profundidad}
    end

    def convertir_movimiento_linea(mov) do
      "#{mov.codigo}@#{mov.idCiudad}@#{mov.horaInicio}@#{mov.horaFin}@#{mov.magnitud}@#{mov.profundidad}"
    end

    def convertir_linea_movimiento(linea) do
        [codigo, idCiudad, horaInicio, horaFin, magnitud, profundidad] =
            linea
            |> String.split("@")
            |> Enum.map(&String.trim/1)
        horaInicio = Time.from_iso8601(horaInicio)
        horaFin = Time.from_iso8601(horaFin)
        magnitud = Util.parse_float(magnitud)
        profundidad = String.to_integer(profundidad)

        crear(codigo,idCiudad,horaInicio,horaFin,magnitud,profundidad)
        end

end
