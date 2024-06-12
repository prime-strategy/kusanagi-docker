# KUSANGI Runs on Dockerの使い方

## KUSANAGI Runs on Docker(以下RoD)について

KUSANAGI Runs on Docker(以下RoD)は、KUSANAGIの機能をDocker composeを使用して提供するものです。

RoDの利用確認済みOSは、以下のとおりです。

- CentOS7 or later
- Ubuntu18.04 or later
- Windows10(WSL+Docker for Windows. 非推奨)
- Windows10/Windows11(WSL2+Docker for Windows)
- Windows10/Windows11(WSL2+Docker CE)
- Mac(with Docker for mac)

RoDを使用するために必要なソフトウェアは以下のものになります。

- bash(4.x 以上)
- git
- sed
- awk
- grep
- gettext
- envsubst
- curl
- python3
- docker(18.0x以上)
- docker-compose


## KUSANAGI RoDのインストール

以下のようにコマンドを実行すると、KUSANAGI RoDが$HOME/.kusanagi 以下にインストールされます。

```shell
$ curl https://raw.githubusercontent.com/prime-strategy/kusanagi-docker/master/install.sh | bash 
cloning kusanagi-docker commands
Cloning into '/home/kusanagi/.kusanagi'...
remote: Enumerating objects: 193, done.
remote: Counting objects: 100% (193/193), done.
remote: Compressing objects: 100% (123/123), done.
remote: Total 573 (delta 124), reused 125 (delta 67), pack-reused 380
Receiving objects: 100% (573/573), 195.00 KiB | 452.00 KiB/s, done.
Resolving deltas: 100% (308/308), done.
check commands requires kusanagi-docker
kusanagi-docker command install completes.
Please add these line to .bashrc or .zshrc
export PATH=/home/kusanagi/.kusanagi/bin:$PATH
$
```

上記メッセージのように、$HOME/.kusanagi/bin をPATHに追加してください。
KUSANAGI RoDを更新するときは、$HOME/.kusanagi/install.sh を再実行してください。
KUSANAGI RoDで使用するイメージを最新版にするときは、$HOME/.kusanagi/ update_version.shを実行してください。

## KUSANAGI RoDコマンド

KUSANAGI RoDコマンドの本体は、$HOME/.kusanagi/bin/kusanagi-docker となります。

以下はヘルプメッセージになります。

```
$ kusanagi-docker --help
///////////////////////////////////////////////////
High-Performance WordPress VirtualMachine
///////////////////////////////////////////////////
     __ ____  _______ ___    _   _____   __________
    / //_/ / / / ___//   |  / | / /   | / ____/  _/
   / ,< / / / /\__ \/ /| | /  |/ / /| |/ / __ / /
  / /| / /_/ /___/ / ___ |/ /|  / ___ / /_/ // /
 /_/ |_\____//____/_/  |_/_/ |_/_/  |_\____/___/

KUSANAGI-DOCKER CLI Subcommand inforamtion
Manual : http://en.kusanagi.tokyo/document/command/
---------------------
- help -
# kusanagi-docker [-h | --help | help]
show this snippet.
# kusanagi-docker [-V|--version]
show this version
---------------------
- create/remove target -
provision [options] --fqdn domainname target(like kusanagi.tokyo)
    [--wp|--wordpress|--WordPress [WPOPTION]|
    WPOPTION:
         --wplang lang(like en_US, ja)]
         [--admin-user admin] [--admin-pass pass] [--admin-email email]
         [--wp-title title] [--kusanagi-pass pass] [--noftp|--no-ftp] |
     --lamp|--c5|--concrete5|--concrete|
     --drupal|--drupal9|--drupal10]
    [--nginx|--httpd]
    [--nginx1.26|--nginx126|
     --nginx1.27|--nginx127|--nginx=version]
    [--http-port port][--tls-port port]
    [--php8.1|--php81|
     --php8.2|--php82|
     --php8.3|--php83|--php=version]
    [--mariadb10.5|--mariadb105|
     --mariadb10.6|--mariadb106|
     --mariadb10.11|--mariadb1011|
     --mariadb11.4|--mariadb114]
    [--dbhost host]
    [--dbport port]
    [--dbrootpass pasword
    [--dbname dbname]
    [--dbuser username]
    [--dbpass password]
remove [-y] [target]
- configuration (runs on target dir) -
ssl [options]
    [--cert file --key file]
    [--redirect|--noredirect]
    [--hsts [on|off]]
    [--oscp [on|off]]
    [--ct [on|off]]
    [--help|help]
config command
    bcache [on|off]
    fcache [on|off]
    pull
    push
    dbdump [file]
    dbrestore [file]
    backup
    restore
    [--help|help]
wp [wpcli commands]
import/export
---------------------
- status (runs on target dir) -
start|stop|restart|status
----------------------
```

主なサブコマンドは以下になります。

- provision
  KUSANAGI RoDの環境を作成します
- remove
  KUSANAGI RoDの環境を削除します
- ssl
  KUSANAGI RoDのSSL関連の設定を変更します
- config
  KUSANAGI RoD を設定を変更します
- wp
  WordPressのCLIコマンドを実施します(WordPressのみ)
- import/export
  Docker上に設定したファイルおよびDB情報をローカルディレクトリにimport/exportします
- start/stop/restart
  作成したKUSANAGI RoD環境を開始/停止/再起動します
- status
  作成したKUSANAGI RoD環境の状態を確認します



## provision

provisionサブコマンドでは、末尾に指定したtarget名のディレクトリをカレントディレクトリ以下に作成し、KUSANAGI RoDの環境を作成します。

### provisonサブコマンドのオプション

provision サブコマンドのオプションは以下のとおりです。

| オプション                                | 環境変数                         | 説明                                                         |
| ----------------------------------------- | -------------------------------- | ------------------------------------------------------------ |
| --fqdn  ドメイン名(必須)                  | FQDN                             | 作成するサイトのドメイン名を指定します。                     |
| --wp/--wordpress/--WordPress              | APP=wp                           | WordPressの環境を構築します。環境変数APPを指定したり、--c5/--lamp/--drupalなどを設定しない場合は、このオプションが設定されます。 |
| --wplang lang                             | WP_LANG                          | WordPressの言語を一つだけ指定します。無指定時は、en_US となります。 |
| --admin-user admin                        | ADMIN_USER                       | WordPressの管理者ユーザ名を指定します。無指定時はランダム文字列となります。 |
| --admin-pass pass                         | ADMIN_PASS                       | WordPressの管理者パスワードを指定します。無指定時はランダム文字列となります。 |
| --admin-email email                       | ADMIN_EMAIL                      | WordPressの管理者メールアドレスを指定します。無指定時は、$ADMIN_USER@$FQDN となります。 |
| --wp-title title                          | WP_TITLE                         | WordPressのタイトルを指定します。無指定時は「WordPress」となります。 |
| --kusanagi-pass pass                      | KUSANAGI_PASS                    | WordPressでの更新で使用するkusanagiユーザのパスワードを指定します。無指定時はランダム文字列となります。 |
| --noftp/--no-ftp                          |                                  | WordPressでの更新用のftpを使用しません。                     |
| --c5/--concrete5/--concrete               | APP=c5                           | Concreate CMS の環境を構築します。php74/php80で動作します。  |
| --lamp/--LAMP                             | APP=lamp                         | LAMPの環境を構築します。                                     |
| --drupal9                       | APP=drupal<br />DRUPAL_VERSION=9 | drupal9の環境を構築します。                           |
| --drupal10/--drupal                                | APP=drupal<br />DRUPAL_VERSION=10 | drupal10の環境を構築します。                      |
| --httpd                                   |                                  | httpd(Apache 2.4)を使用します。--nginxと同時に指定できません。 |
| --nginx                                   |                                  | nginxを使用します。--httpdと同時に指定できません。無指定時はnginxが使用されます。 |
| --nginx1.26/--nginx126                    |                                  | nginx使用時に、kusanagi-nginx:1.26.x を使用します。 |
| --nginx1.27/--nginx127                    |                                  | nginx使用時に、kusanagi-nginx:1.27.x を使用します。無指定時はkusanagi-nginx:1.27.xを使用します。 |
| --nginx=version                           |                                  | nginx使用時に、Docker Hub に公開されている任意のバージョンを使用します。1.25以前のバージョンを指定できますが、すでに更新していないため、自己責任でご使用ください。 |
| --http-port num                           | HTTP_PORT                        | ホストにポートフォワードするhttpポート番号を指定します。無指定時は80が指定されます。使用済みのポートを選択した場合、構築に失敗します。 |
| --tls-port num                            | HTTP_TLS_PORT                    | ホストにポートフォワードするhttpsポート番号を指定します。無指定時は443が指定されます。使用済みのポートを選択した場合、構築に失敗します。 |
| --php8.3/--php81                          |                                  | kusanagi-php:8.3.xを使用します。                             |
| --php8.2/--php81                          |                                  | kusanagi-php:8.2.xを使用します。                             |
| --php8.1/--php81                          |                                  | kusanagi-php:8.1.xを使用します。                             |
| --php=version                             |                                  | DockerHub上にある任意のバージョンのPHPを使用します。         |
| --mariadb11.4/--mariadb114                |                                  | DBとして、mariadb:11.4.x-noble を使用します。                 |
| --mariadb10.11/--mariadb1011              |                                  | DBとして、mariadb:10.11.x-jammy を使用します。                |
| --mariadb10.6/--mariadb106                |                                  | DBとして、mariadb:10.6.x-focal を使用します。mariadbのバージョンを指定しない場合、mariadb:10.6.x-focalを使用します。 |
| --mariadb10.5/--mariadb105                |                                  | DBとして、mariadb:10.5.x-focal を使用します。                |
| --dbhost host                             | DBHOST                           | 接続するDBホスト名を指定します。無指定時はlocalhostです。    |
| --dbport port                             | DBHOST                           | 接続するDBホストのポート番号を指定します。無指定時は3306です。    |
| --dbrootpass pass                         | DB_ROOTPASS                      | 接続するDBホストのrootパスワードを指定します。無指定時はランダム文字列となります。 |
| --dbname name                             | DBNAME                           | 接続するDB名を指定します。無指定時はランダム文字列となります。 |
| --dbuser user                             | DBUSER                           | 接続するDBユーザ名を指定します。無指定時はランダム文字列となります。 |
| --dbpass pass                             | DBPASS                           | 接続するDBパスワードを指定します。無指定時はランダム文字列となります。 |

- オプションは、--option value もしくは、--option=value の形で指定できます。
- オプション指定の優先順位は、オプション指定、環境変数指定、デフォルト値となります。
- DBHOSTにlocalhost以外を指定する場合、使用するDBがあらかじめ作成され、DBNAME/DBUSER/DBPASSでアクセス可能であることが必要です。

### ターゲットディレクトリ

プロビジョンが成功すると、ターゲットディレクトリに以下のファイル・ディレクトリが作成されます。

| ファイル・ディレクトリ名 | 説明                                               |
| ------------------------ | -------------------------------------------------- |
| .kusanagi.\*              | docker-composeで使用する環境変数が記述されています |
| docker-compose.yml       | docker-composeの設定ファイル                       |
| contents                 | Docker上に作成されたコンテンツディレクトリのコピー |
| .git                     | git用のディレクトリ                                |

プロビジョンが終わったあと、contents ディレクトリ以下にプロビジョンで生成されたDocker上のファイルをコピーし、Git登録済みの状態になり、管理できます。



### 作成されるDockerコンテナ

provision後、以下のDockerコンテナが起動されます。

| 名称    | 説明                                                         |
| ------- | ------------------------------------------------------------ |
| httpd   | nginxもしくはhttpdが動作します。httpdコンテナは、httpdブリッジを通じてホスト側のネットワークからHTTP/TLSポートをポートフォワードして、Webサービスを行います。kusanagiボリューム内のアプリケーションディレクトリをrootディレクトリとして動作します。 |
| php     | PHP-FPMが動作します。httpd コンテナとの通信はhttpdのネットワークを共有して行います。アプリケーションはkusanagiボリュームに配置します。DBとはDBボリューム上のソケットファイルを使用して接続します。<br />phpコンテナには、ssmtpコマンドが搭載されており、外部サーバへのSMTP転送が可能です。 |
| db      | MariaDBもしくは、PostgreSQLが動作します。外部のDBサーバ使用時には作成されません。dbはDBボリュームを使用しDBテーブルなどを配置し、socketファイル経由でphpと通信します。 |
| config  | 通常停止していますが、kusanagi-docker config での操作時に起動します。<br />kusanagi-docker configコマンドは、kusanagiおよびdbボリュームを操作し、アプリケーション配置・バックアップ・リストアなどを行います。<br />WordPress構築時はwpcli のイメージが使用され、WorPressのプラグイン・テーマ・言語などのインストール、アンインストールなどの操作できます。 |
| ftp     | WordPressでprovisionしたときのみ起動します。phpコンテナからftp通信し、WordPress core・プラグイン・テーマの更新を、WordPressのWeb画面経由で行います。 |


![KUSANAGI RoD イメージ](RoD.png)



provision実行後に作成されるdocker-compose.yml は、最低限の設定を記述しています。
logging方式の変更、共有ストレージの使用、swarm化などは、docker-compose.yml を修正して対応してください。また、docker-composeを使用して、start/stop/ps/run/exec などの操作が可能です。



### その他環境変数

provision実行時に、環境変数でのみ設定できる項目があります。これらの環境変数は、.kusanagi.\* に書かれます。

| 環境変数              | デフォルト値   | 説明                                                         |
| --------------------- | -------------- | ------------------------------------------------------------ |
| DOCUMENTROOT          | DocumentRoot   | /home/kusanagi/$PROFILE以下に作成する、アプリケーションディレクトリ名を指定します。concrete5のときは**public**となります。 |
| NO_USE_FCACHE         | 1              | FCACHEを使用しないかどうかを指定します。使用しない場合に1を指定します。このオプションは、httpd使用時には無視されます。 |
| NO_USE_BCACHE         | 1              | BCACHEを使用しないかどうかを指定します。使用しない場合に1を指定します。このオプションは、WordPress使用時以外では無視されます。 |
| USE_SSL_CT            | off            | SSLのCT(Certificate Transparency) を有効にするかを指定します。on/offを指定できます。USE_SSL_CTは、SSL自己証明書を使用する場合は指定できません。 |
| USE_SSL_OSCP          | off            | OCSP(Online Certificate Status Protocol)を有効にするかどうかを指定します。on/offを指定できます。USE_SSL_OSCPは、SSL自己証明書を使用する場合は指定できません。 |
| OSCP_RESOLV           |                | OSCP使用時のDNSを指定します。無指定の場合は、8.8.4.4および8.8.8.8が使用されます。 |
| NO_USE_NAXSI          | 1              | NAXSIを使用しないかどうかを指定します。使用しない場合には1を指定します。 |
| NO_SSL_REDIRECT       | 1              | TLSポートへのリダイレクトを行うかどうかを指定します。使用しない場合には1を指定します。 |
| EXPIRE_DAYS           | 90             | nginxでのexpiresヘッダの日数を指定します。                   |
| PHP_PORT              | 127.0.0.1:9000 | PHP-FPMのLISTENポートを指定します。                          |
| PHP_MAX_CHILDLEN      | 500            | PHP-FPMの同時に処理をする可能性がある子プロセス数を指定します。 |
| PHP_START_SERVERS     | 10             | PHP-FPMのプロセス開始時に生成される子プロセス数を指定します。 |
| PHP_MIN_SPARE_SERVERS | 5              | PHP-FPMの待ち状態の子プロセスの最小の数を指定します。        |
| PHP_MAX_SPARE_SERVERS | 10             | PHP-FPMの待ち状態の子プロセスの最大の数を指定します。        |
| PHP_MAX_REQUESTS      | 500            | PHP-FPMの各子プロセスが、再起動するまでに実行するリクエスト数を指定します。 |
| MAILSERVER            | localhost      | PHPコンテナからメール転送する際の、転送先メールサーバを指定します。 |
| MAILDOMAIN            |                | PHPコンテナからメール送信する際の、ドメイン名を指定します。  |
| MAILUSER              |                | PHPコンテナからメール送信する際の、ユーザ名を指定します      |
| MAILPASS              |                | PHPコンテナからメール送信する際の、SMTP-AUTHで使用するパスワードを指定します |
| MAILAUTH              |                | PHPコンテナからメール送信する際の、SMTP-AUTHの方法を指定します。 |



## remove

provisionで作成したRoD環境を削除します。このとき、作成されたDockerコンテナ、ボリューム、ブリッジの停止/削除と、ターゲットディレクトリを削除します。

このコマンドは、ターゲットディレクトリの親ディレクトリ上で動作する必要があります。

## ssl

RoD環境のSSL周りの設定を変更します。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。

| オプション                         | 説明                                                         | デフォルト値  |
| ---------------------------------- | ------------------------------------------------------------ | ------------- |
| --cert file --key file             | SSL証明書と鍵のセットをSSL鍵として使用します                 | 自己SSL証明書 |
| --redirect \|<br /> --noredirect   | SSLへのリダイレクトの有無を指定します                        | 無            |
| --hsts on\|off                     | hsts(HTTP Strict Transport Security)をonにするかどうかを指定します | off           |
| --oscp on\|off                     | OSCP(Online Certificate Status Protocol)をonにするかどうかを指定します | off           |
| --ct on\|off                       | CT(Certificate Transparency)をonにするかどうかを指定します   | off           |

--hsts、--oscp、--ct は、自己SSL証明書を指定していると指定できないのに注意してください。



## config

configコマンドは、RoD環境の設定や、情報のbackup/restore を行います。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。

| サブコマンド     | 説明                                                         |
| ---------------- | ------------------------------------------------------------ |
| bcache on \| off | bcache のon/offの設定する(初期値はoff)                     |
| fcache on \| off | fcache のon/offの設定する(初期値はoff、nginx使用時のみ有効) |
| pull             | kusanagiボリュームの情報をcontens以下にダウンロードする       |
| push             | contens以下の内容をKUSANAGIボリュームへアップロードする      |
| dbdump [file]    | DBのdump情報をターゲットディレクトリ上のデータファイル(無指定時はdbdump)に出力する |
| dbrestore [file] | ターゲットディレクトリ上のデータファイル(無指定時はdbdump)をDBにrestoreする |
| backup           | pull とdbdumpを同時に行う                                    |
| restore          | pushとdbrestoreを同時に行う                                  |

pullおよびdbdumpを実行しても、自動的にGitにcommitされません。適宜git コマンドを使用して管理してください。



## wp

WordPressを使用しているときのみ使用できます。wpcliのコマンドを指定することで、WordPressに対する操作できます。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。



## import/export

kusanagi-docker config backup/restore と同じ動作をします。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。



## start/stop/restart/status

start/stop/restartは、RoD環境のDockerコンテナを開始・停止・再起動します。statusはDockerコンテナの状況を確認できます。また、httpd/php/db/ftp などコンテナ名を指定することで、特定コンテナだけを開始・停止/再起動出来ます。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。

これらのコマンドは、docker-composeコマンドのwrapperなので、ターゲットディレクトリ上でdocker-composeを使用しても構いません。



## 使用されるDocker イメージ

KUSANAGI RoD向けのイメージは[DockerHub](https://hub.docker.com)で公開済みです。すべてalpine10ベースのイメージですが、今後変更される可能性があります。
推奨バージョン(現状の最新版)を使用するには、$HOME/.kusanagi/update_version を定期的に実行してください。

| 名称                                                         | 説明                                                        |
| ------------------------------------------------------------ | ----------------------------------------------------------- |
| [kusanagi-nginx](https://hub.docker.com/r/primestrategy/kusanagi-nginx) | nginxイメージ(推奨はメインラインの最新版)                   |
| [kusanagi-httpd](https://hub.docker.com/r/primestrategy/kusanagi-httpd) | httpd(Apache 2.4) イメージ                                   |
| [kusanagi-php](https://hub.docker.com/r/primestrategy/kusanagi-php) | PHP-FPMイメージ(推奨は7.4の最新版)                               |
| [kusanagi-config](https://hub.docker.com/r/primestrategy/kusanagi-config) | kusanagi config コマンド用イメージ                          |
| [wordpress:cli](https://hub.docker.com/_/wordpress)          | WordPress構築時用のconfig コマンドイメージ                  |
| [kusanagi-ftpd](https://hub.docker.com/r/primestrategy/kusanagi-ftpd) | WordPress構築時のみ使用するvsftpdを起動するコンテナイメージ |
| [mariadb](https://hub.docker.com/_/mariadb)                  | MariaDBイメージ                                               |
| [postgresql](https://hub.docker.com/_/postgres)              | PostgreSQLイメージ                                          |
| [certbot](https://hub.docker.com/r/certbot/certbot)          | Certbotイメージ                                             |


