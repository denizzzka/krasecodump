Description / Описание:
=======================

Dumps eco-monitoring info from Krasnoyarsk officials

Эта утилита предназначена для сбора и сохранения данных об экологии
Красноярского края с сайта Центра реализации мероприятий по
природопользованию и охране окружающей среды Красноярского края
(http://www.krasecology.ru/)


Сборка:
======

Утилита написана на языке D (https://dlang.org/).
Установите компилятор D и менеджер пакетов DUB, после чего запустите
сборку в директории репозитория командой:

$ dub build

В результате будет получен исполняемый файл "krasecodump".


Запуск
======

В СУБД Postgres создайте базу данных по схеме из файла db_schema.sql
Схема этой БД сконструирована для долговременного хранения большого
объёма собранных данных.

Запускать утилиту нужно так:
$ krasecodump "строка подключения к БД Postgres"

При каждом своём запуске утилита запрашивает все данные со всех постов
наблюдения, записывает их в БД, после чего завершается. При каждом
повторном запуске новая информация будет дописана в БД.

Данные на сайте обновляются с периодичностью 20 минут.

Рекомендуется запускать утилиту чаще чтобы гарантировано не пропустить
новые метеоданные - они остаются доступными лишь в течении 20 минут.


Пример настройки таймера systemd:
=================================

$ cat ~/.config/systemd/user/krasecodump.timer
[Unit]
Description=Krasecodump periodic start

[Timer]
OnCalendar=*:5,15,25,35,45,55:00
Persistent=true

[Install]
WantedBy=default.target


Пример настройки юнита systemd:
===============================

$ cat ~/.config/systemd/user/krasecodump.service
[Unit]
Description=Dumps eco-monitoring info from Krasnoyarsk officials

[Service]
Type=oneshot
WorkingDirectory=/path_to/krasecodump
ExecStart=/path_to/krasecodump "dbname=krasecodump"

[Install]
WantedBy=default.target
