# この ec-cube4_installer ってなに?

詳しく言えば、「EC-CUBE4の公式パッケージをUbuntu環境に導入する時短ansible-playbook 〜PostgreSQL/Nginx/Let's EncryptのSSL証明書とともに〜」です。

EC-CUBE環境を、公式サイトで案内されているDockerへのインストール ([Docker Composeを使用してインストールする \- < for EC\-CUBE 4 Developers />](https://doc4.ec-cube.net/quickstart/docker_compose_install)) ではなくて、諸事情によりいわば直接の状態で構築したかったのです。そこでせっかくだからansible-playbookの形で構築手順を書いてみようと思いました。

## 動作確認を行った環境

|項目|内容|
|---|---|
|EC-CUBE|4.2.0|
|サーバOS|Ubuntu 22.04.01 LTS (amd64)|
|DBサーバ|PostgreSQL 14.6 (Ubuntu 14.6-0ubuntu0.22.04.1)|
|WEBサーバ|nginx/1.18.0|
|PHP|8.1.2-1ubuntu2.10|
|Certbot|2.3.0|

※2023-02-18時点の情報です。

## 使い方

次のansible-playbookを1〜6まで適用していくと、PostgreSQL+Nginx+SSL証明書まで整ったUbuntuサーバ環境の上に、EC-CUBE環境ができあがります。それなりの時短が達成できるかと思います。ansibleのベストプラクティスに乗っ取った作りではない点はご了承ください。

- [sudo_1_setup-server.ansible.yml](tasks/sudo_1_setup-server.ansible.yml) : サーバとなるUbuntu環境の初期設定を行います。
- [sudo_2_setup-certbot.ansible.yml](tasks/sudo_2_setup-certbot.ansible.yml) : Certbotをセットアップして、Let's EncryptのSSL証明書を取得します (Google Cloud DNSの併用が前提の作り)。
- [sudo_3_setup-nginx.ansible.yml](tasks/sudo_3_setup-nginx.ansible.yml) : Nginxとphp-fpmをセットアップします。
- [sudo_4_setup-postgresql.ansible.yml](tasks/sudo_4_setup-postgresql.ansible.yml) : PostgreSQLをセットアップして、EC-CUBEに必要なDBとユーザの作成を行います。
- [sudo_5_install-eccube.ansible.yml](tasks/sudo_5_install-eccube.ansible.yml) : EC-CUBEのアーカイブを公式サイトからダウンロードしてサーバ上に展開し、composerの力を借りて必要なPHPモジュールも導入します。
- [sudo_6_switchenv-eccube.ansible.yml](tasks/sudo_6_switchenv-eccube.ansible.yml) : EC-CUBEの動作環境を切り替えます。ウェブインストーラーでの初期設定が完了した後に適用してください。

なお逆に、次のansible-playbookはPostgreSQLにセットアップした環境を初期化します。環境を作り直すときに便利かと。

- [sudo_9_destroy-postgresql.ansible.yml](tasks/sudo_9_destroy-postgresql.ansible.yml) : PostgreSQLに作成したEC-CUBE4用のデータベースとユーザを削除します。

### おまけ

[ansible-player.sh](ansible-player.sh)というシェルスクリプトを同梱しています。

このスクリプトには、(1) ansibleに適用するinventoryファイルを環境変数`HOSTS_SELECT`で切り替える機能と、(2) 実行するansible-playbookファイルの選択を数値入力で行える機能があります。

(1) たとえば次の実行例では、「HOSTS_SELECT=**SAMPLE**」と指定してあるので、ansibleのinventoryファイルとして同じ階層にある「hosts_**SAMPLE**.txt」が使用されます。
```
$ HOSTS_SELECT=SAMPLE ./ansible-player.sh
1) sudo_1_setup-server.ansible.yml
2) sudo_2_setup-certbot.ansible.yml
3) sudo_3_setup-nginx.ansible.yml
4) sudo_4_setup-postgresql.ansible.yml
5) sudo_5_install-eccube.ansible.yml
6) sudo_6_switchenv-eccube.ansible.yml
7) sudo_9_destroy-postgresql.ansible.yml
8) QUIT
#?
```

(2) また、このスクリプトを介してのplaybook実行はdry-runとなるようにしており基本的に安全です。playbookをいよいよ本番実行する時は、スクリプトが最後に標準出力する文字列をコピペして、端末画面に貼り付ければ実行可能です。
