defmodule Main do

  def probar_punto1() do
    IO.puts("\n=== INICIANDO PRUEBA DEL PUNTO 1 ===")
    Coordinador.reporte_local()
    IO.puts("=== FIN DEL PUNTO 1 ===\n")
  end

  def arrancar_servidor() do
    IO.puts("\n=== ARRANCANDO SERVIDOR (PUNTO 2) ===")
    Servidor.iniciar()
  end

  def arrancar_cliente(nodo_servidor) do
    IO.puts("\n=== ARRANCANDO CLIENTE (PUNTO 2) ===")
    # nodo_servidor debe ser un átomo, por ejemplo: :"servidor@tu-computador"
    Cliente.iniciar(nodo_servidor)
  end
end
#Main.probar_punto1()
#Main.arrancar_servidor() #iex --sname servidor main.exs
#Main.arrancar_cliente(:"servidor@omnibook") #iex --sname cliente main.exs
#compilacion: elixirc punto-1/coordinador.exs punto-1/cuidad.ex punto-1/reporte.exs punto-1/movimiento.ex punto-1/util.ex punto-1/csv.exs punto-2/nodo-servidor/nodo_servidor.exs punto-2/nodo-cliente/nodo_cliente.exs
