# KUSANGI Runs on Dockerの使い方

## KUSANAGI Runs on Docker(以下RoD)について

KUSANAGI Runs on Docker(以下RoD)は、KUSANAGIの機能をDocker composeを使用して提供するものです。

RoDの使用を確認済みのOSは、以下のとおりです。

- CentOS7
- Ubuntu18.04
- Windows10(WSL+Docker for Windows)
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
- docker(18.0x以上)
- docker-compose
- docker-machine(オプショナル)


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

上記メッセージのように、$HOME/.kusanagi/bin をPATHに追加しておいてください。
KUSANAGI RoDを更新するときは、$HOME/.kusanagi/install.sh を再実行してください。

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
         [--wp-title title] [--kusanagi-pass pass] [--notfp|--no-ftp] |
     --lamp|--c5|--concrete5|
     --drupal|--drupal7|--drupal8]

    [--nginx|--httpd]
    [--http-port port][--tls-port port]
    [--dbsystem mysql|mariadb|pgsql|postgrsql]
    [--dbhost host]
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
    [--ct [on|off] 
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
INFO: 完了しました。
```

主なサブコマンドは以下になります。

- provision
  KUSANAGI RoDの環境を作成します
- remove
  KUSANAGI RoDの環境を削除します
- ssl
  KUSANAGI RoDのSSL関連の設定を変更します
- config
  KUSANAGI RoD の設定を行います
- wp
  WordPressのCLIコマンドを実施します(WordPressのみ)
- import/export
  Docker上に設定したファイルおよびDB情報をローカルディレクトリにimport/exportします
- start/stop/restart
  作成したKUSANAGI RoD環境を開始/停止/再起動を行います
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
| --admin-user admin                         | ADMIN_USER                       | WordPressの管理者ユーザ名を指定します。無指定時はランダム文字列となります。 |
| --admin-pass pass                       | ADMIN_PASS                       | WordPressの管理者パスワードを指定します。無指定時はランダム文字列となります。 |
| --admin-email email                       | ADMIN_EMAIL                      | WordPressの管理者メールアドレスを指定します。無指定時は、$ADMIN_USER@$FQDN となります。 |
| --wp-title title                          | WP_TITLE                         | WordPressのタイトルを指定します。無指定時は「WordPress」となります。 |
| --kusanagi-pass pass                      | KUSANAGI_PASS                    | WordPressでの更新で使用するkusanagiユーザのパスワードを指定します。無指定時はランダム文字列となります。 |
| --noftp/--no-ftp                          |                                  | WordPressでの更新用のftpを使用しません。                     |
| --c5/--concrete5                          | APP=c5                           | Concreate5の環境を構築します。                               |
| --lamp/--LAMP                             | APP=lamp                         | LAMPの環境を構築します。                                     |
| --drupal7                                 | APP=drupal<br />DRUPAL_VERSION=7 | drupal7の環境を構築します。                                  |
| --drupal/--drupal8                        | APP=drupal<br />DRUPAL_VERSION=8 | drupal8の環境を構築します。                                  |
| --httpd                                   |                                  | httpd(Apache 2.4)を使用します。--nginxと同時に指定できません。 |
| --nginx                                   |                                  | nginxを使用します。--httpdと同時に指定できません。無指定時はnginxが使用されます。 |
| --http-port num                           | HTTP_PORT                        | ホストにポートフォワードするhttpポート番号を指定します。無指定時は80が指定されます。使用済みのポートを選択した場合、構築に失敗します。 |
| --tls-port num                            | HTTP_TLS_PORT                    | ホストにポートフォワードするhttpsポート番号を指定します。無指定時は443が指定されます。使用済みのポートを選択した場合、構築に失敗します。 |
| --dbsystem MySQL/mariadb/ pgsql/postgreql | KUSANAGI_DB_SYSTEM= MySQL/pgsql  | 使用するDBシステムを指定します。ただし、WordPressおよびdrupal7/drupal8は必ずMySQLを使用します。postgresql は現在実験中です。 |
| --dbhost host                             | DBHOST                           | 接続するDBホスト名を指定します。無指定時はlocalhostです。    |
| --dbrootpass pass                         | DB_ROOTPASS                      | 接続するDBホストのrootパスワードを指定します。無指定時はランダム文字列となります。 |
| --dbname name                             | DBNAME                           | 接続するDB名を指定します。無指定時はランダム文字列となります。 |
| --dbuser user                             | DBUSER                           | 接続するDBユーザ名を指定します。無指定時はランダム文字列となります。 |
| --dbpass pass                             | DBPASS                           | 接続するDBパスワードを指定します。無指定時はランダム文字列となります。 |

- オプションは、--option value もしくは、--option=value の形で指定できます。
- オプション指定の優先順位は、オプション指定、環境変数指定、デフォルト値となります。
- DBHOSTにlocalhost以外を指定し、使用するDBが作成されていない場合、DB_ROOTPASSを正しく指定する必要があります。
- DBHOSTにlocalhost以外を指定し、使用するDBが作成している場合、DBNAME/DBUSER/DBPASSを正しく指定する必要があります。

### ターゲットディレクトリ

プロビジョンが成功すると、ターゲットディレクトリに以下のファイル・ディレクトリが作成されます。

| ファイル・ディレクトリ名 | 説明                                               |
| ------------------------ | -------------------------------------------------- |
| .kusanagi.\*              | docker-composeで使用する環境変数が記述されています |
| docker-compose.yml       | docker-composeの設定ファイル                       |
| contents                 | Docker上に作成されたコンテンツディレクトリのコピー |
| .Git                     | Git用のディレクトリ                                |

プロビジョンが終わったあと、contents ディレクトリ以下にプロビジョンで生成されたDocker上のファイルをコピーし、Git登録済みの状態になり、管理を行うことが出来ます。



### 作成されるDockerコンテナ

provision後、以下のDockerコンテナが起動されます。

| 名称    | 説明                                                         |
| ------- | ------------------------------------------------------------ |
| httpd   | nginxもしくはhttpdが動作します。httpdコンテナは、httpdブリッジを通じてホスト側のネットワークからHTTP/TLSポートをポートフォワードして、Webサービスを行います。kusanagiボリューム内のアプリケーションディレクトリをrootディレクトリとして動作します。 |
| php     | PHP-FPMが動作します。httpd コンテナとの通信はhttpdのネットワークを共有して行います。アプリケーションはkusanagiボリュームに配置します。DBとはDBボリューム上のソケットファイルを使用して接続します。<br />phpコンテナには、ssmtpコマンドが搭載されており、外部サーバへのSMTP転送が可能です。 |
| db      | MySQLもしくは、Postgresqlが動作します。外部のDBサーバ使用時には作成されません。dbはDBボリュームを使用しDBテーブルなどを配置し、socketファイル経由でphpと通信します。 |
| config  | 通常停止していますが、kusanagi-docker config での操作時に起動します。<br />kusanagi-docker configコマンドは、kusanagiおよびdbボリュームを操作し、アプリケーション配置・バックアップ・リストアなどを行います。<br />WordPress構築時はwpcli のイメージが使用され、WorPressのプラグイン・テーマ・言語などのインストール、アンインストールなどの操作を行うことも出来ます。 |
| ftp     | WordPressでprovisionしたときのみ起動します。phpコンテナからftp通信し、WordPress core・プラグイン・テーマの更新を、WordPressのWeb画面経由で行います。 |
| certbot | let's encryptからSSL証明書を取得します(現在実験中で使用方法を公開していません)。 |



![KUSANAGI RoD イメージ](RoD.png)



provision実行後に作成されるdocker-compose.yml は、最低限の記述しかしていません。
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

RoD環境のSSL周りの設定を行います。

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
| bcache on \| off | bcache のon/offの設定を行う(初期値はoff)                     |
| fcache on \| off | fcache のon/offの設定を行う(初期値はoff、nginx使用時のみ有効) |
| pull             | KUSANGIボリュームの情報をcontens以下にダウンロードする       |
| push             | contens以下の内容をKUSANAGIボリュームへアップロードする      |
| dbdump [file]    | DBのdump情報をターゲットディレクトリ上のデータファイル(無指定時はdbdump)に出力する |
| dbrestore [file] | ターゲットディレクトリ上のデータファイル(無指定時はdbdump)をDBにrestoreする |
| backup           | pull とdbdumpを同時に行う                                    |
| restore          | pushとdbrestoreを同時に行う                                  |

pullおよびdbdumpを実行しても、自動的にGitにcommitされません。適宜git コマンドを使用して管理してください。



## wp

WordPressを使用しているときのみ使用できます。wpcliのコマンドを指定することで、WordPressに対する操作を行うことが出来ます。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。



## import/export

kusanagi-docker config backup/restore と同じ動作をします。

このコマンドは、ターゲットディレクトリ上で動作する必要があります。



## start/stop/restart/status

start/stop/restartは、RoD環境のDockerコンテナを開始・停止・再起動を行います。statusはDockerコンテナの状況を確認することが出来ます。また、httpd/php/db/ftp などコンテナ名を指定することで、特定コンテナだけを開始・停止/再起動を行うことが出来ます

このコマンドは、ターゲットディレクトリ上で動作する必要があります。

これらのコマンドは、docker-composeコマンドのwrapperなので、ターゲットディレクトリ上でdocker-composeを使用しても構いません。



## 使用されるDocker イメージ

KUSANAGI RoD向けのイメージは[DockerHub](https://hub.docker.com)で公開済みです。すべてalpine10ベースのイメージですが、今後変更される可能性があります。
推奨バージョン(現状の最新版)を使用するには、$HOME/.kusanagi/update_version を定期的に実行してください。

| 名称                                                         | 説明                                                        |
| ------------------------------------------------------------ | ----------------------------------------------------------- |
| [kusanagi-nginx](https://hub.docker.com/r/primestrategy/kusanagi-nginx) | nginxイメージ(推奨はメインラインの最新版)                   |
| [kusanagi-httpd](https://hub.docker.com/r/primestrategy/kusanagi-httpd) | httpd(Apache 2.4) イメージ                                   |
| [kusanagi-php](https://hub.docker.com/r/primestrategy/kusanagi-php) | PHP-FPMイメージ(推奨は最新版)                               |
| [kusanagi-config](https://hub.docker.com/r/primestrategy/kusanagi-config) | kusanagi config コマンド用イメージ                          |
| [wordpress:cli](https://hub.docker.com/_/wordpress)          | WordPress構築時用のconfig コマンドイメージ                  |
| [kusanagi-ftpd](https://hub.docker.com/r/primestrategy/kusanagi-ftpd) | WordPress構築時のみ使用するvsftpdを起動するコンテナイメージ |
| [mariadb](https://hub.docker.com/_/mariadb)                  | MySQLイメージ                                               |
| [postgresql](https://hub.docker.com/_/postgres)              | Postgresqlイメージ                                          |
| [certbot](https://hub.docker.com/r/certbot/certbot)          | Certbotイメージ                                             |



## docker-machineとの併用

KUSANAGI RoDは、docker-machineと併用することが出来ます。通常通りdocker-machineを作成し、```eval $(docker-machine env ホスト名```を実行して、kusanagi-docker provisionを行ってください。

また以下の手順で、既存コンテナを別docker-machineへ移行することが可能です。

1. ```kusanagi-docker import```を実施して、現状のコンテナ情報をimportする

2. ```kusanagi-docker stop```でコンテナを停止

3. ```eval $(docker-machine env ホスト名```を実行

4. ```docker-compose up -d```を実行

5. DBがlocalhostの場合、DB初期化まで待つ。
   初期化が終わったかどうかは、以下のコマンドで確認可能。

   ```
   $ source .kusanagi.db
   $ docker-compose run --rm config  mysqladmin status -u$DBUSER -p"$DBPASS" 2>&1 > /dev/null && echo ok || echo ng
   ```

6. ```kusanagi-docker export```を実行し、コンテナ情報をexportする.

