defmodule Reporte do

  def generar(ciudades_validas, movimientos_validos, rechazos_ciudades, rechazos_movimientos) do
    reportes_ciudades = Enum.map(ciudades_validas, fn ciudad ->
      movimientos_ciudad = Enum.filter(movimientos_validos, fn movimiento -> movimiento.id_ciudad == ciudad.id end)
      formatear_ciudad(ciudad, movimientos_ciudad)
    end)

    reporte_final = Enum.join(reportes_ciudades, "\n") <>
      "\nRechazados Ciudades: #{rechazos_ciudades}\nRechazados Movimientos: #{rechazos_movimientos}\n"

    reporte_final
  end

  defp formatear_ciudad(ciudad, []) do
    "#{ciudad.nombre} (#{ciudad.habitantes} hab.)\nSin movimientos registrados. Total: 0 | Max: No aplica | Prof Promedio: No aplica\n"
  end

  defp formatear_ciudad(ciudad, movimientos) do
    # Recursividad explícita
    {total, max_mov, suma_prof} = calcular_stats(movimientos, 0, nil, 0.0)
    promedio = suma_prof / total

    mensaje = Enum.map(movimientos, fn mov -> "  - #{mov.codigo} | #{mov.magnitud} | #{mov.profundidad}km"  end) |> Enum.join("\n")

    "#{ciudad.nombre} (#{ciudad.habitantes} hab.)\n#{mensaje}\nTotal: #{total} | Max: #{max_mov.codigo} (#{max_mov.magnitud}) | Prof Promedio: #{Util.formater(promedio)}\n"
  end


  defp calcular_stats([], total, max_mov, suma_prof), do: {total, max_mov, suma_prof}

  defp calcular_stats([mov | resto], total, max_mov, suma_prof) do
    nuevo_maximo = if max_mov == nil or mov.magnitud > max_mov.magnitud, do: mov, else: max_mov
    calcular_stats(resto, total + 1, nuevo_maximo, suma_prof + mov.profundidad)
  end
end
