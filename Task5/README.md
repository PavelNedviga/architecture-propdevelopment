# Задание 5. Управление трафиком внутри кластера Kubertnetes

В этом задании вам нужно разграничить трафик между сервисами, которые развёрнуты в кластере Kubernetes:

Вам необходимо добавить новый сервис. В терминах Kubernetes это под (pod). При этом нужно запретить другим подам с ним взаимодействовать.
Необходимо изолировать трафик к новому сервису от других подов.

## Что нужно сделать

1. В кластере, внутри одного namespace, вам необходимо развернуть четыре сервиса. В качестве самого сервиса используйте образ Nginx (вам не нужно создавать логику приложения в этом заданий).

2. Назначьте метки для сервисов

    Метки выполняют функцию ролей для сервиса:

    1. `front-end`
    2. `back-end-api`
    3. `admin-front-end`
    4. `admin-back-end-api`

    Для назначения меток используйте команду:

    ```bash
    kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
    ```

    > 💡 Сервис можно назвать, добавив суффикс -app к имени сервиса. Так будет проще различать имя сервиса и его метку.

3. Создайте сетевые политики

    Настройте сетевые политики так, чтобы разделить трафик между сервисами API (admin-back-end-api, back-end-api) и сервисами, которые используют их UI (front-end, admin-front-end).

    Таким образом, сетевые политики должны разрешить сетевой трафик в обе стороны между парой сервисов front-end и back-end-api, а также admin-front-end и admin-back-end-api.

    Сохраните сетевую политику в файл. Можете назвать его non-admin-api-allow.yaml. Затем примените сетевую политику, используя команду:

    ```bash
    kubectl apply -f non-admin-api-allow.yaml
    ```

4. Когда настроите и примените сетевые политики, проверьте, что трафик есть между сервисами, для которых он разрешён, но его нет между сервисами, для которых он запрещён. Для этого используйте команду:

    ```bash
    kubectl run test-$RANDOM --rm -i -t --image=alpine -- sh
        / # wget -qO- --timeout=2 http://apiserver
    ```

Когда всё будет готово, загрузите файл с сетевыми политиками в директорию Task5.

## Решение

0. Перезапустили minikube: `minikube delete && minikube start --cni=calico`

1. Создаем `namespace`:

   ```bash
   kubectl create namespace app-ns
   ```

2. Создаем 4 pod+service (по одному порту 80/TCP)

   ```bash
    kubectl -n app-ns run front-end-app --image=nginx --port 80 --expose --labels role=front-end
    kubectl -n app-ns run back-end-api-app --image=nginx --port 80 --expose --labels role=back-end-api
    kubectl -n app-ns run admin-front-end-app --image=nginx --port 80 --expose --labels role=admin-front-end
    kubectl -n app-ns run admin-back-end-api-app --image=nginx --port 80 --expose --labels role=admin-back-end-api
   ```

3. Применяем политики:

    ```bash
    kubectl apply -f traffic-isolation.yaml
    ```

4. Проверяем: `kubectl -n app-ns run test-$RANDOM --rm -i --restart=Never --image=alpine --labels role=front-end -- wget -qO- --timeout=2 http://back-end-api-app && echo "✅ allowed"`

    ```bash
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    <style>
    html { color-scheme: light dark; }
    body { width: 35em; margin: 0 auto;
    font-family: Tahoma, Verdana, Arial, sans-serif; }
    </style>
    </head>
    <body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and
    working. Further configuration is required.</p>

    <p>For online documentation and support please refer to
    <a href="http://nginx.org/">nginx.org</a>.<br/>
    Commercial support is available at
    <a href="http://nginx.com/">nginx.com</a>.</p>

    <p><em>Thank you for using nginx.</em></p>
    </body>
    </html>
    pod "test-6137" deleted
    ✅ allowed
    ```

    Проверяем: `kubectl -n app-ns run test-$RANDOM --rm -i --restart=Never --image=alpine --labels role=front-end -- wget -qO- --timeout=2 http://admin-back-end-api-app || echo "🚫 blocked as expected"`

    ```bash
    Вывод:
    If you don't see a command prompt, try pressing enter.
    wget: download timed out
    pod "test-3169" deleted
    pod app-ns/test-3169 terminated (Error)
    🚫 blocked as expected
    ```
