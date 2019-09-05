---
title: "Buildah + Source2Image"
date: 2019-09-05T10:35:00+02:00
draft: false
---

# Remember - no Dockerfiles

Многие разработчики разочарованы в магии современного контейнерного подхода.

Кроме дополнительных требований к приложению (см. [The Twelve-Factor Apps](https://12factor.net/)) им зачастую приходится еще и учить новый формат для сборки контейнеров - Dockerfile. Изначально формат был достаточно простым - `FROM`, `RUN` да `COPY`, но затем этот формат оброс дополнительными конструкциями - `COPY --from` и `FROM foo as bar` для multistage builds, `ONBUILD` и так далее. Кроме того, формат не стандартизирован никак и управляется целиком и полностью желаниями Docker Inc.

Но Dockerfile - не единственный способ сборки контейнерных образов. Рассмотрим некоторые из них.


## Buildah

[Buildah](https://buildah.io/) - это инструмент, который специально создан только для сборки контейнерных образов. В отличие от `docker` он не требует демона, может быть [запущен в другом контейнере](https://developers.redhat.com/blog/2019/08/14/best-practices-for-running-buildah-in-a-container) и позволяет более гибко собирать контейнерные образы.

Рассмотрим пример:
```shell
echo "--- Сборка приложения, никаких контейнеров ---"
./configure --with-feature=a
make
echo "Приложение собрано в ./output/bin/my-app"

echo "--- Сборка контейнера ---"

echo "Создаем пустой контейнер и смонтируем его"
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount $newcontainer)

echo "Устанавливаем bash и coreutils из репозиториев Fedora 30 в контейнер используя dnf из хоста"
dnf install --installroot $scratchmnt --releasever 30 bash coreutils --setopt install_weak_deps=false -y

echo "Копируем бинарный файл в /usr/bin/ контейнера"
cp ./output/bin/my-app $scratchmnt/usr/bin

echo "Устанавливаем CMD ['/usr/bin/my-app']"
buildah config --cmd /usr/bin/my-app $newcontainer
buildah commit $newcontainer my-app:latest
```
(для Debian/Ubuntu систем подход немного сложнее - `apt-get download package && dpkg -i package.deb --force-not-root --root=$scratchmnt`)

В чем приемущество такого подхода? Вот несколько примеров:

* [Distroless-подход](https://github.com/GoogleContainerTools/distroless/blob/master/README.md) - в образе не будет инструментов для сборки - нет dnf/apt-get
* Для сборки не требуются привилегии для запуска приложений в контейнере -> сборку контейнерного образа можно запускать в другом контейнере без требования флага `priviledged`
* Во всем контейнере создастся три слоя - `FROM scratch`, `COPY <необходимые бинарные файлы из coreutils + bash + my-app>` и `CMD ['/usr/bin/app']`
* Кэшированием артефактов для сборки управляет сборочный хост - можно свободно использовать [distcc](https://github.com/distcc/distcc), сетевые диски для кэша и т.д.

Эти образы совместимы со спецификацией OCI, а значит их можно запускать в docker, docker-compose или Kubernetes так же, как и собранные в docker.

### buildah bud

Кроме того, `buildah` поддерживает чтение инструкций из Dockerfile: `buildah bud -f Dockerfile .`. Инструкции из Dockerfile преобразуются в инструкции по созданию новых контейнеров и копированию файлов аналогично предыдущему примеру.

Этот способ так же позволяет монтировать внешние директории для сборки контейнеров: `buildah bud --volume /var/lib/my-build-cache:/cache:ro,Z -t imageName .`

## Source2Image

Еще в древности люди заметили что фреймворк или целый язык программирования имеет стандартизированный алгоритм для сборки:

* `golang`: `go get && go build`
* `rust`: `cargo build --release`
* `python`: `pip install -r requirements.txt && pip install .`

Кроме того, при переходе на новую версию приходится менять все Dockerfile, убедится что базовый образ в один прекрасный день не обновит golang или python до неподдерживаемой версии и т.д.

Чтобы избежать копипаста кусков в Dockerfiles и упрощения процесса сборки был создан инструмент под названием [Source-to-Image](https://github.com/openshift/source-to-image).

После установки [s2i](https://github.com/openshift/source-to-image/releases) сборка простого питоновского проекта сокращается до одной команды:
```
s2i build https://github.com/sclorg/django-ex centos/python-36-centos7 hello-python
```

Это консольное приложение выполняет следующие действия:
* Клонирует репозиторий `https://github.com/sclorg/django-ex` во временную директорию
* Тянет образ `docker.io/centos/python-36-centos7` - в этом образе хранятся инструкции (подробнее ниже) и необходимые инструменты
* Используя питон и инструкции из `python-36-centos7` создается новый образ `hello-python`

Если требуется собирать приложение с другой версией питона, то при сборке нужно лишь сменить сборочный образ - к примеру `docker.io/centos/python-27-centos7`

Вся "магия" сборки хранится в сборочном образе. [Краткое описание](https://github.com/openshift/source-to-image#anatomy-of-a-builder-image) процесса сборки:

* `s2i` ищет каталог `s2i/bin/` в сборочном образе
* при сборке образа запускается скрипт из `s2i/bin/assemble`
* при старте собранного образа запускается `s2i/bin/run`
* (опционально) скрипт из `s2i/bin/usage` добавит описание в контейнерный образ
* (опционально) скрипт из `s2i/bin/save-artifact` позволяет использовать предыдущие сборки для кэширования артефактов сборки

Этот простой интерфейс позволяет отделить процедуру сборки приложения от исходников и обновлять их независимо. Source2Image, к примеру, используется в OpenShift (дистрибутиве kubernetes) для быстрого и безопасного создания пайпланов из git-репозиториев.

### Заключение

Существует множество инструментов для сборки контейнерных образов без использования Dockerfile. Многие могут показаться черезчур усложненными (а некоторые - черезчур упрощенными), но фактически Dockerfiles до сих пор остаются неформализированным стандартом. Тем не менее важно знать преимущества других способов сборки - а так же из недостатки.

К примеру, этот блогпост был собран с помощью https://github.com/vrutkovs/sti-hugo
