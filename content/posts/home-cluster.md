---
title: "k8s at home for fun and leisure"
date: 2019-09-20T10:35:00+02:00
draft: false
comments:
  host: social.vrutkovs.eu
  username: vadim
  id: none
---

# Потому что могу

У домашнего кластера на Kubernetes может быть несколько применений - от файлохранилки до хостинга
личного блога. Но главным из них, безусловно, является оттачивание навыков. Теперь не только ваша
команды \ клиенты зависят от надежности и производительности, но и лично вы. Других стимулов кроме
"я смог это сделать" не стоит ждать (см. [IKEA effect](https://en.wikipedia.org/wiki/IKEA_effect)).

Но почему именно Kubernetes? Ответ довольно прост - он довольно снисходительно относится к
неожиданным перекройкам инфраструктуры. Не нужно переносить systemd сервисы на другую машины -
достаточно ввести новую ноду в кластер. Одно из приложений внезапно стало нагружать процессор - ему
установить разумный лимит, проверив потребление через мониторинг.

Кроме того, несмотря на применение в крупных компаниях, Kubernetes кластер не заставляет тащить
стойки с оборудованием домой - вполне достаточно нескольких старых десктопов или ноутбуков.

Некоторые вопросы установки оставим вне рамок этой статьи - например разворачивание на одной машине
(будет не так интересно) или использование Raspberry Pi для кластера
(для таких нод потребуются имаджи для другой архитектуры).

# Поделки из желудей и пластилина

Итак, есть некоторое количество оборудования, которое требуется объединить в кластер. В моем случае:

* ноутбук Lenovo x240 с 8 ГБ памяти, 250 Гб SSD для корневого диска и 500 Гб HDD для данных
* старый десктоп в формате mini-ITX, 8 Гб RAM и Athlon времен взятия Очакова, 250 Гб SSD для корня и 500 Гб HDD

На обе машины была установлена Fedora Atomic 29. Выбор ОС - дело каждого, в моем случае привычнее
скачивать апдейты в оффлайне и иметь возможность откатится на прошлую версию (эти и другие
преимущества описаны [тут](https://www.projectatomic.io/docs/os-updates/))

Дистрибутивом Kubernetes был выбран OpenShift по принципу "выбирай тот который использует ближайший
к тебе отзывчивый эксперт". В наличии только 2 машины, потому приходится пользоваться релизом OKD 3.11
вместо OCP 4.

# Наш человек в Гаване

Мой провайдер запрещает внешние коннекты к портам 80 и 22, потому для внешнего доступа нам потребуется
виртуальная машина в публичном хостинге с хорошей репутацией. В моем случае это Fedora CoreOS на
Digital Ocean.

Она служит как промежуточный хост для reverse ssh tunnel - из машины в кластере
(bmo.vrutkovs.eu) устанавливается ssh соединение в сокет `/run/bmo.sock` на машине в DO (`do.vrutkovs.eu`).
Таким образом, если послать данные в сокет bmo.sock они попадут на нужный порт в машине bmo.

Для этого достаточно запустить `autossh`:
```
/usr/bin/docker run --name %n -it  \
  -v /root/.ssh/vrutkovs.pem:/id_rsa:z \
  -e SSH_HOSTNAME=vrutkovs.eu \
  -e SSH_TUNNEL_REMOTE=/run/bmo.sock \
  -e SSH_TUNNEL_HOST=172.17.0.1 \
  -e SSH_TUNNEL_LOCAL=443 \
  jnovack/autossh
```

Теперь на `do.vrutkovs.eu` мы может перенаправлять запросы на внутренний сервер с помощью haproxy.
Часть конфига:
```
frontend https
    bind *:443
    mode tcp
    default_backend bmo

backend bmo
    mode tcp
    server bmo /run/bmo.sock
```

Кроме того `do.vrutkovs.eu` может служить как машина для почтового сервера и получения Let's Encrypt
сертификатов. Для простоты обслуживания проще получить wildcard сертификат, который затем будет
применять роутер опеншифта.

# Сердце тьмы
Основой всего будет OpenShift, потому нам потребуется развернуть его на внутренних серверах с помощью
openshift-ansible.

Процесс установки довольно специфичен и сложен, да и объяснить его лучше чем
[документация](https://docs.openshift.com/container-platform/3.11/install/index.html) сложно. Вот
несколько рекомендаций

Научит роутер применять наши LetsEncrypt сертификаты:
```
openshift_master_overwrite_named_certificates: true
openshift_master_named_certificates:
- certfile: "{{ inventory_dir }}/vrutkovs.eu.crt"
  keyfile: "{{ inventory_dir }}/vrutkovs.eu.key"
  names:
    - "vrutkovs.eu"
  cafile: "{{ inventory_dir }}/letsencrypt.ca.crt"
```

Все роуты будут получать поддомен автоматически:
```
openshift_master_default_subdomain: vrutkovs.eu
```

OpenShift рекомендуется запускать на машинах с 16 Гб памяти, поэтому:
```
openshift_disable_check: memory_availability
```

После установки консоль будет доступна по адресу https://console.vrutkovs.eu

# Always Own Your Platform

Что с этим кластером теперь делать? Я следую принципу [Always Own Your Platform](http://www.alwaysownyourplatform.com/).
Потому необходимыми для меня приложениями являются:

* [gitea](https://gitea.io/) - git сервер
* [nextcloud](https://nextcloud.com/) - сервер синхронизации файлов, RSS-читалка и многое другое
* [transmission](https://transmissionbt.com/) - битторрент клиент (только чтобы скачивать linux дистрибутивы)
* [jackett](https://github.com/Jackett/Jackett) - API для битторрент серверов
* [sonarr](https://github.com/Sonarr/Sonarr) - информация о сериалах
* [lidarr](https://github.com/lidarr/Lidarr/) - информация о музыке
* [этот блог](https://github.com/vrutkovs/blog)

Некоторые другие вещи (например Matrix сервер или Mastodon) пока приходится отложить из-за низкой скорости интернета.

Другие полезные идеи для приложений можно почерпнуть из огромного списка - [awesome-selfhosted](https://github.com/Kickball/awesome-selfhosted)

# Домашние заготовки

Некоторые полезные вещи для домашнего кластера:

* [скрипт](https://github.com/vrutkovs/homelab-openshift-ci/blob/master/git-cluster-state.sh) для сохранения состояния кластера (`oc get --export` объектов и создание коммита во внутреннем репозитории)
* [tekton](https://github.com/tektoncd/pipeline) для CI - например, автоматического импорта свежих изменений в ImageStream
* [local provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) - для выделения локальных каталогов подам
* [nfs provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs) - для выделения NFS каталогов подам
* [alertmanager-bot](https://github.com/metalmatze/alertmanager-bot) - Telegram бот для событий из Alertmanager
* [nightshift](https://github.com/joyrex2001/nightshift) - бот для управления деплойментами по календарю
* [conumser](https://github.com/vrutkovs/conumser/) - Telegram бот для обработки вебхуков
* [blackbox exporter](https://github.com/prometheus/blackbox_exporter) - для мониторинга инфры и доступности сайтов


# Выводы

Одомашенный Kubernetes - это совсем не страшно, главное найти полезное применения старому оборудованию
и внимательно следить за алертами из мониторинга.
