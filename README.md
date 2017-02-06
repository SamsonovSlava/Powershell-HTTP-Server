# Powershell-HTTP-Server
With Powershell HTTP Server you can run powershell commandlets, scripts or run remote powershell functions from *nix systems
by calling simple xml-requests over http/https protocol. It is useful for integration *nix and Windows systems. For example
you can manage windows users from your linux server by executing simple curl commands or even create new Hyper-V VM from Linux.

Позволяет выполнять Powershell запросы по http/https с поддержкой авторизации.
Запросы отправляются методом Post в формате xml или json, ответ также приходит в формате xml или json.
Поддерживается кодировка UTF8.

Варианты использования:
Интеграция non-windows систем (*nix) с платформой Windows.
Безопасное выполнение команд на сервере через единственный открытый порт на Firewall.

Возможно настроить отказоустойчивость с помощью организации кластера и службы перекрестного мониторинга с оповещением о падении одного из узлов.

Возможен запуск удаленных функций с передачей параметров.

Запуск удаленных скриптов.

Запуск команд на удаленной стороне с получением ответа в формате xml или json.

Пример клиента для linux.
Пример клиента на posh.
