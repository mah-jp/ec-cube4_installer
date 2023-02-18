# EC-CUBE4の公式パッケージをUbuntu環境に導入してSSL証明書も取得するansible-playbook 〜PostgreSQL+Nginx+Certbot〜

## 動作確認を行った環境

|項目|内容|
|---|---|
|EC-CUBE|4.2.0|
|サーバOS|Ubuntu 22.04.01 LTS (amd64)|
|DBサーバ|PostgreSQL 14.6 (Ubuntu 14.6-0ubuntu0.22.04.1)|
|WEBサーバ|nginx/1.18.0|
|PHP|8.1.2-1ubuntu2.10|

## 使い方

次のansible-playbookをこの順序で1〜6まで適用していくと、EC-CUBE環境ができあがります。

- sudo_1_setup-server.ansible.yml : サーバとなるUbuntu環境の初期設定を行います。
- sudo_2_setup-certbot.ansible.yml : Certbotをセットアップして、Let's EncryptからSSL証明書を取得します (現時点ではGoogle Cloud DNS限定)。
- sudo_3_setup-nginx.ansible.yml : Nginxをセットアップします。
- sudo_4_setup-postgresql.ansible.yml : PostgreSQLをセットアップして、EC-CUBEに必要なDBとユーザの作成を行います。
- sudo_5_install-eccube.ansible.yml : EC-CUBEのアーカイブを公式サイトからダウンロードしてサーバ上に設置し、必要なPHPモジュールも併せて導入します。
- sudo_6_switchenv-eccube.ansible.yml : EC-CUBEの動作環境を切り替えます。ウェブインストーラーでの初期設定が完了した後に適用してください。

なお、次のansible-playbookはPostgreSQLにセットアップした環境を初期化します。環境を作り直すときに便利かと。

- sudo_9_destroy-postgresql.ansible.yml

### おまけ

ansible-player.shというシェルスクリプトを同梱しています。このスクリプトには、ansibleに適用するinventoryファイルを環境変数`HOSTS_SELECT`で切り替える機能と、実行するansible-playbookファイルの選択を数値入力で行える機能があります。また、このスクリプトを介してのplaybook実行は必ずdry-runとなるようにしており基本的に安全です。playbookの本番実行は、スクリプトがdry-run時に最後に出力する文字列をコピペして、端末に貼り付ければ可能です。

たとえば次の実行例では、「HOSTS_SELECT=**SAMPLE**」と指定してあるので、inventoryファイルとして同じ階層にある「hosts_**SAMPLE**.txt」が使用されます。
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
