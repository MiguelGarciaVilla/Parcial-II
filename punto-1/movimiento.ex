defmodule Movimiento do
    defstruct codigo: "", idCiudad: "", horaInicio: ~T[00:00:00], horaFin: ~T[00:00:00], magnitud: 0.0, profundidad: 0.0

    def crear(codigo,idCiudad,horaInicio,horaFin,magnitud,profundidad) do
      %Movimiento{codigo: codigo, idCiudad: idCiudad, horaInicio: horaInicio, horaFin: horaFin, magnitud: magnitud, profundidad: profundidad}
    end

    def convertir_movimiento_linea(mov) do
      "#{mov.codigo}@#{mov.idCiudad}@#{Time.to_string(mov.horaInicio)}@#{Time.to_string(mov.horaFin)}@#{mov.magnitud}@#{mov.profundidad}"
    end

    def convertir_linea_movimiento(linea) do
      [codigo, idCiudad, horaInicio, horaFin, magnitud, profundidad] =
        linea
        |> String.split("@")
        |> Enum.map(&String.trim/1)
      {atomo1, horaInicio} = Time.from_iso8601(horaInicio)
      {atomo2, horaFin} = Time.from_iso8601(horaFin)
      magnitud = Util.parse_float(magnitud)
      profundidad = Util.parse_float(profundidad)

      if validar_hora(atomo1) and validar_hora(atomo2) and validar_float(magnitud) and validar_float(profundidad) do
        crear(codigo,idCiudad,horaInicio,horaFin,magnitud,profundidad)
      else
        :error
      end
    end

    defp validar_hora(atomo) do
      case atomo do
        :ok -> true
        :error -> false
      end
    end

    defp validar_float(float) when is_float(float) and float > 0, do: true
    defp validar_float(_float), do: false

end
