# KV001
Программирование контроллера КВ-001, версия 1.091
# Программа работает с контроллером КВ-001, версия 1.091
# С периодичностью заданной в программе (по умолчанию 10 секунд) опрашиваются регистры
#  1. значение веса в счетчике отвесов, начальный адрес 125($7D), возвращает 4 байта тип float
#  2. значение кол-ва отвесов, начальный адрес 127 ($7F), возвращает 2 байта тип longint
#  3. значение веса в последнем отвесе, начальный адрес 128 (80э$)? озвращает 4 байта тип float
# (пока считываем  с адреса $81  т.к есть рассхождения в документации, выясненно путем
# мониторинга COM порта при работающей программе Удаленный терминал КВ-001 (поставляемая с контроллером))
# Результаты записываются в этот файл. Разделитель между считанными значениями ";"
# Если в результате обмена с портом(контроллером) обнаруживаются ошибки, то строка записывемая в файл начинается с "#"
#
# Настройки программы после выхода cохраняются в ini файл.
#
#
