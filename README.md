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

### 1. リポジトリをcloneして環境に合わせた設定を用意

```
git clone --depth=1 https://github.com/mah-jp/ec-cube4_installer
cd ec-cube4_installer
cp -a hosts_SAMPLE.txt hosts_HOGE.txt
vim hosts_HOGE.txt # 環境に合わせて内容を書き換えてください
```

### 2. ansible-playbookを順次適用

公開鍵認証でのSSHログインを可能にしたUbuntuサーバへ、下記のansible-playbookを1〜5まで適用していくと、PostgreSQL+Nginx+SSL証明書まで整ったEC-CUBE環境ができあがります。それなりの時短が達成できるかと思います。ansibleのベストプラクティスに乗っ取った作りではない点はご了承ください。

- [sudo_1_setup-server.ansible.yml](tasks/sudo_1_setup-server.ansible.yml) : サーバとなるUbuntu環境の初期設定を行います。
- [sudo_2_setup-certbot.ansible.yml](tasks/sudo_2_setup-certbot.ansible.yml) : Certbotをセットアップして、Let's EncryptのSSL証明書を取得します (Google Cloud DNSの併用が前提の作り)。
- [sudo_3_setup-nginx.ansible.yml](tasks/sudo_3_setup-nginx.ansible.yml) : Nginxとphp-fpmをセットアップします。
- [sudo_4_setup-postgresql.ansible.yml](tasks/sudo_4_setup-postgresql.ansible.yml) : PostgreSQLをセットアップして、EC-CUBEに必要なDBとユーザの作成を行います。
- [sudo_5_install-eccube.ansible.yml](tasks/sudo_5_install-eccube.ansible.yml) : EC-CUBEのアーカイブを公式サイトからダウンロードしてサーバ上に展開し、composerの力を借りて必要なPHPモジュールも導入します。
- [sudo_6_switchenv-eccube.ansible.yml](tasks/sudo_6_switchenv-eccube.ansible.yml) : EC-CUBEの動作環境 (開発環境←→プロダクション環境) を切り替えます。ウェブインストーラーでの初期設定が完了した後に適用してください。

#### a. 1個ずつ確認しながら適用

```
# 1番目のplaybook実行例
ansible-playbook -i ./hosts_HOGE.txt --diff --check --ask-become-pass ./tasks/sudo_1_setup-server.ansible.yml # まずは --check
ansible-playbook -i ./hosts_HOGE.txt --diff         --ask-become-pass ./tasks/sudo_1_setup-server.ansible.yml # 本番実行

# 以降、2〜5番目まで実行を続けるとEC-CUBEのウェブインストーラーでの初期設定が行えるようになります
```

#### b. まとめて適用

```
# まずは --check ありで動作を確認
ansible-playbook -i ./hosts_HOGE.txt --diff --check --ask-become-pass \
	./tasks/sudo_1_setup-server.ansible.yml \
	./tasks/sudo_2_setup-certbot.ansible.yml \
	./tasks/sudo_3_setup-nginx.ansible.yml \
	./tasks/sudo_4_setup-postgresql.ansible.yml \
	./tasks/sudo_5_install-eccube.ansible.yml

# 問題なさそうなら --check を外して実行してください☕
```

### 3. 再初期化のときには

次のansible-playbookはPostgreSQLにセットアップした環境を初期化します。DB環境を作り直すときに使用します。

- [sudo_9_destroy-postgresql.ansible.yml](tasks/sudo_9_destroy-postgresql.ansible.yml) : PostgreSQLに作成したEC-CUBE4用のデータベースとユーザを削除します。

### おまけ

[ansible-player.sh](ansible-player.sh)というシェルスクリプトを同梱しています。このスクリプトには、(1) ansibleに適用するinventoryファイルを環境変数`HOSTS_SELECT`で切り替える機能と、(2) 実行するansible-playbookファイルの選択を数値入力で行える機能があります。

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

(2) このスクリプトを介してのplaybook実行は `--check (dry-run)` となるように設定しており基本的に安全です。playbookをいよいよ本番実行する時は、スクリプトが最後に標準出力する文字列をコピペして、端末画面に貼り付ければ実行可能です。
